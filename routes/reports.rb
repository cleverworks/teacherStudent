# Deliver the daily report with all statistics on Teams channel
get '/reports/deliver' do
  # default filter
  set_time = Date.parse(params[:date]) rescue Date.yesterday
  pay_data = Payment.where(created_at: {"$gte" => set_time.beginning_of_day, "$lte" => set_time.end_of_day}, status: "TXN_SUCCESS").to_a
  disp_data = Dispense.where(created_at: {"$gte" => set_time.beginning_of_day, "$lte" => set_time.end_of_day}).not(payment_id: nil).to_a
  call_data = Feedback.where(created_at: {"$gte" => set_time.beginning_of_day, "$lte" => set_time.end_of_day}).count

  # Unused Machines
  mids = Machine.live.pluck(:mid)
  unused = mids - pay_data.map(&:mid).uniq

  fail_data = {}
  result = {
    payments: pay_data.count,
    amount: (pay_data.sum(&:amount) rescue 0),
    dispenses: disp_data.count,
    calls: call_data,
    unused_machines: unused,
    stats: disp_data.group_by{|x| (x.resultData["MSG"] rescue "Unknown")}.map{|k,v| 
      k == "Unknown" ? (v.group_by{|d| d.mid}.map{|mid, vls| fail_data[mid] = vls.count}; {"#{k} #{v.count}" => fail_data}) : {"#{k}" => v.count}
    }
  }
  Notification.create(title: "System Report #{set_time.strftime("%d-%m-%Y")}" ,messageData: result)
  result.to_json
end

# Dispense report for machine (stats)
get '/reports/dispenses/:imei' do
  # default filter
  return [].to_json if params[:imei].blank?
  disps = {}
  Dispense.only(:created_at, :resultData, :imei, :mid, :status).
    where(imei: params[:imei], created_at: {"$lt" => Time.now-1.minute}).
    order(created_at: :desc).limit(100).group_by{|x| (x.resultData["MSG"] rescue "Unknown")}.map{|k,v| disps[k] = v.count}
  disps.to_json
end

# Failure report specifically for reporting failures
get '/reports/failures' do
  # default filter
  return [].to_json if params[:mode].blank?
  fails = []
  if params[:mode] == Machine::MODES[:live]
    Dispense.only(:created_at, :resultData, :imei, :mid, :payment_id, :status).
      not(payment_id: nil, "resultData.MSG" => "SUCCESS").
      where(created_at: {"$lt" => Time.now-1.minute}).
      order(created_at: :desc).limit(20).map{|x| fails << x}
  else
    Dispense.only(:created_at,:resultData, :imei, :mid, :status).
      not("resultData.MSG" => "SUCCESS").
      where(payment_id: nil, created_at: {"$lt" => Time.now-1.minute}).
      order(created_at: :desc).limit(20).map{|x| fails << x}
  end
  fails.to_json
end

# battry replacements detection
get '/reports/battery/:imei' do |imei|
  sts = Machine.find_by(imei: imei).battery_changes
  sts.to_json
end

# Detailed Sales report
get '/reports/sales' do
  # default filter
  q = {created_at: {"$gte" => Date.today.beginning_of_day, "$lte" => Date.today.end_of_day}}
  q[:created_at]["$gte"] = Date.parse(params[:start_date]).beginning_of_day if params[:start_date].present?
  q[:created_at]["$lte"] = Date.parse(params[:end_date]).end_of_day if params[:end_date].present?
  q[:mid] = {"$in" => params[:mids]} if params[:mids].present?

  # Uncomment when the mids can be handled
  # if q[:mid].blank?
    # Get running averages and applicable machines
    mc_data = {}
    Machine.live.only(:mid, :running_avg).map{|x| mc_data[x.mid] = x.running_avg}
    # Set filter for only live machines
    q[:mid] = {"$in" => mc_data.keys} if params[:mids].blank?
  # end

  # Filter only successful payments on Live Machines
  pays = Payment.where(q).where(status: "TXN_SUCCESS", paySignature: true)
  # Get all dispenses
  disps = Dispense.where(q).not(payment_id: nil)

  report_data = {}
  report_data[:start_date] = q[:created_at]["$gte"]
  report_data[:end_date] = q[:created_at]["$lte"]
  report_data[:ravg] = (mc_data.values.sum rescue 0)
  report_data[:travg] = (mc_data.values.sum/mc_data.size rescue 0)
  report_data[:payments] = pays.count
  report_data[:disps] = 0
  report_data[:rows] = []

  # Form Dispense data groups
  # { "MID" => { "STATUS" => [Paymnents], "STATUS2" => [Payments2]... }}
  disp_grp = {}
  disps.group_by{|x| x.mid }.map{|g,ps| 
    disp_grp[g] = ps.group_by{ |y| (y.resultData["MSG"] rescue "Unknown")}; disp_grp[g]["count"] = ps.count
  }

  # Compile payment reports array
  # MID |  Payments |  Amount | Dispenses |  Successful |  Failed |  Refunded
  mid_list = []
  payment_list = pays.group_by{|x| x.mid}.map{|mid, ps| 
    mid_list << mid
    # disp_grp[mid] = {"count" => 0} if disp_grp[mid].blank?
    sdisp = disp_grp[mid]["SUCCESS"].count rescue 0
    report_data[:disps] += sdisp
    report_data[:rows] << [
      mid, 
      mc_data[mid],
      ps.count, 
      ps.sum{|p| p.amount}, 
      disp_grp[mid]["count"], 
      sdisp, 
      (disp_grp[mid]["count"] - sdisp), 
      ps.select(&:refunded).count 
    ]
  }

  # Add all MIDs which are live but don't have any payments with 0 values to the payments list
  # (mc_data.keys - mid_list rescue []).map{|mid| report_data[:rows] << [mid, mc_data[mid], 0, 0, 0, 0, 0, 0]}
  
  report_data.to_json
end

# API to drive the System overview report
# Overview consists of:
# Commissioning reports:
# 1. Total Machines
# 2. Total Machines Live
# 3. Total Machines in Test mode
# 4. Total Machines in Maintenance / Offline mode
# Revenue reports:
# 1. Total Revenue
# 2. Total Refunds (Revenue Loss)
# 3. Business Losses (total) - Refund processed and capsule dispensed
# 4. Split up of reasons for Revenue loss:
#   - DISP_FAIL
#   - SEN_FAIL
#   - ACK
#   - TIME_FAIL
#   - DUP_DATA
get '/reports/overview' do
  # Get machine commissioning data
  mc_data = {}
  Machine.collection.aggregate([
    {"$group" => {
      "_id" => "$mode",
      "count" => {"$sum" => 1}
    }}
  ]).map{|x| mc_data[x["_id"]] = x["count"]}

  # total of all genuine payments
  total_revenue = Payment.where(status: "TXN_SUCCESS", paySignature: true).sum(:amount)

  # Get revenue data
  rev_data = Payment.collection.aggregate([
    {"$match" => {
      status: "TXN_SUCCESS", 
      paySignature: true, 
      created_at: {"$gte" => Date.today - 7.days, "$lte" => Date.today.end_of_day}
    }},
    {"$group" => {
      "_id" => {dispensed: "$dispensed", refunded: "$refunded"},
      "count" => {"$sum" => 1},
      "amount" => {"$sum" => "$amount"}
    }}
  ]).to_a
  # re-organize data as follows:
  # total_revenue - sum of all counts
  # net_revenue - rev_data with _id dispensed: true, refunded: false
  # rev_loss - rev_data with _id dispensed: false, refunded: true
  # biz_loss - rev_data with _id dispensed: true, refunded: true
  rev_report = {}
  rev_report[:total] = rev_data.map{|x| x["amount"]}.sum
  rev_report[:net_revenue] = rev_data.select{|x| x["_id"]["dispensed"] == true && x["_id"]["refunded"] == false}.pluck("count","amount").flatten
  rev_report[:rev_loss] = rev_data.select{|x| x["_id"]["dispensed"] == false && x["_id"]["refunded"] == true}.pluck("count","amount").flatten
  rev_report[:biz_loss] = rev_data.select{|x| x["_id"]["dispensed"] == true && x["_id"]["refunded"] == true}.pluck("count","amount").flatten

  # Get dispense failure data
  # Sort data by number of failures descending  
  disp_data = Dispense.collection.aggregate([
    {"$match" => {
      payment_id: {"$ne" => nil},
      "resultData.MSG": {"$ne" => "SUCCESS"},
      # testing: false,
      created_at: {"$gte" => Date.today - 7.days, "$lte" => Date.today.end_of_day}
    }},
    {"$group" => {
      "_id" => "$resultData.MSG",
      "count" => {"$sum" => 1}
    }},
    {"$sort" => {"count" => -1}}
  ]).to_a

  return { machines: mc_data, revenue: rev_report, dispenses: disp_data, rev_total: total_revenue }.to_json
end


# Recompute machine running sales
# background job to be triggered at least once a day
get '/reports/machine_running_avg' do 
  q = {mid: {"$in" => Machine.live.map(&:mid)}, paySignature: true, status: "TXN_SUCCESS"}
  payments = Payment.collection.aggregate([
    {"$match" => q},
    {"$group" => {
      "_id" => { day: { "$dateToString": { format: "%Y-%m-%d", date: "$created_at" } }, mid: "$mid" },
      "count" => {"$sum" => 1}
    }},    
    {"$group" => {
      "_id" => "$_id.mid",
      "count" => {"$avg" => "$count"}
    }}
  ]).to_a
  payments.map{|x| Machine.find_by(mid: x["_id"]).set(running_avg: x["count"].round)}
  return { status: 200, message: "Recomputed" }.to_json
end


# Generate a report of Losses
# Revenue - all incoming payments
# Revenue Losses - payments that were refunded and not dispensed
# Business losses - payments that were dispensed and refunded
get '/reports/revenue' do 
  # Setup filters
  q = {created_at: {"$gte" => Date.yesterday.beginning_of_day, "$lte" => Date.yesterday.end_of_day}}
  q[:created_at]["$gte"] = Date.parse(params[:start_date]).beginning_of_day if params[:start_date].present?
  q[:created_at]["$lte"] = Date.parse(params[:end_date]).end_of_day if params[:end_date].present?
  if params[:mids].present?
    q[:mid] = {"$in" => params[:mids]} 
  else
    q[:mid] = {"$in" => Machine.live.map(&:mid)}
  end

  # Get all payments here and get corresponding dispenses
  # Structure of disp_data is:
  # { mid: { payment_id: { amount: 99.00, refunded: false, dispensed: true, dispense_msg: "Success" } } }
  # and Failures look like:
  # { mid: { payment_id: { amount: 99.00, refunded: true, dispensed: false, dispense_msg: "DISP_FAIL" } } }
  disp_data = {}
  pids = []

  Payment.where(q).only(:mid, :amount, :refunded, :dispensed).group_by{|x| x.mid}.each do |mid, ps|
    disp_data[mid] = {}
    ps.map{|x| pid = x.id; disp_data[mid][pid.to_s] = {amount: x.amount, refunded: x.refunded, dispensed: x.dispensed}; pids << pid}
  end

  Dispense.where(payment_id: {"$in" => pids.flatten}).only(:payment_id, :mid, "resultData.MSG", :created_at, :updated_at).each do |d|
    disp_data[d.mid][d.payment_id.to_s][:dispense_msg] = d.resultData["MSG"] rescue "Unknown"
    # Get dispense time in seconds
    disp_data[d.mid][d.payment_id.to_s][:disp_time] = d.updated_at - d.created_at
  end

  # Calculate the revenue and losses
  revenue_data = {}
  disp_data.each do |mid, ps|
    revenue_data[mid] = { revenue: 0.0, revenue_loss: { amount: 0.0, counts: {} }, business_loss: { amount: 0.0, counts: {} } }
    ps.each do |pid, d|
      revenue_data[mid][:revenue] += d[:amount] if d[:dispensed]
      # Add to revenue loss if refunded
      if d[:refunded]
        revenue_data[mid][:revenue_loss][:amount] += d[:amount]
        revenue_data[mid][:revenue_loss][:counts][d[:dispense_msg]] ||= 0
        revenue_data[mid][:revenue_loss][:counts][d[:dispense_msg]] += 1
      end
      # Add to business loss if refunded and dispensed
      if d[:refunded] and d[:dispensed]
        revenue_data[mid][:business_loss][:amount] += d[:amount]
        revenue_data[mid][:business_loss][:counts][d[:dispense_msg]] ||= { counts: 0, avg_dispense_time: 0.0 }
        revenue_data[mid][:business_loss][:counts][d[:dispense_msg]][:counts] += 1
        revenue_data[mid][:business_loss][:counts][d[:dispense_msg]][:avg_dispense_time] += (d[:disp_time].nil? ? 0.0 : d[:disp_time])
      end
    end
    
    # Calculate average dispense time for business losses
    revenue_data[mid][:business_loss][:counts].each do |msg, data|
      revenue_data[mid][:business_loss][:counts][msg][:avg_dispense_time] /= data[:counts]
    end
  end

  revenue_data.to_json
end

# Sales widget driver
get '/reports/sales_chart' do
  # default filter of last week's report
  q = {created_at: {"$lte" => Date.today.end_of_day, "$gte" => Date.today-7.days}}
  q[:mid] = params[:mid] if params[:mid].present?
  q[:created_at]["$gte"] = Date.parse(params[:start_date]).beginning_of_day unless params[:start_date].blank?
  q[:created_at]["$lte"] = Date.parse(params[:end_date]).end_of_day unless params[:end_date].blank?

  # Sales report shows only successful items
  q[:refunded] = false
  q[:dispensed] = true

  pdata = []

  #TODO - move these reports to stored models
  payments = Payment.where(q).
    group_by{|x| x.created_at.strftime("%d %b, %Y")}.
    map{|date, ps| pdata << {date: date, sales: ps.count} }
  pdata.to_json
end

# Machine wise and date wise sales report
# TODO - move these reports to stored models
# get all machines's MIDs, IMEI and live_date
# get all genuine payments date and MID wise
# Compile machine report in format:
# { mid: { date: { sales: 0 }, days_live: 0 } }
# Eg: { "Spar01203012": { "2016-01-01": { sales: 20 }, days_live: 10 } }
get '/reports/mc_wise_sales' do
  q = {
    # Default to last 1 month
    created_at: {"$gte" => Date.yesterday-30.days, "$lte" => Date.yesterday}, 
    paySignature: true, 
    dispensed: true, 
    status: "TXN_SUCCESS"
  }
  q[:created_at]["$gte"] = Date.parse(params[:start_date]) if params[:start_date].present?
  q[:created_at]["$lte"] = Date.parse(params[:end_date]) if params[:end_date].present?
  
  # Using aggregation pipeline get payments and group by MID, Date and count number of payments
  pay_data = Payment.collection.aggregate([
    {"$match" => q },
    {"$group" => {
      "_id" => { date: { "$dateToString": { format: "%Y-%m-%d", date: "$created_at" } }, mid: "$mid" },
      "sales" => {"$sum" => 1}
    }},
  ]);
  # Get relevant MIDs
  pay_mids = pay_data.map{|x| x["_id"]["mid"]}.uniq
  mc_data = {}
  Machine.live.where(mid: {"$in" => pay_mids}).
    only(:mid, :imei, :live_date).
    map{|x| mc_data[x.mid] = {imei: x.imei, live_date: x.live_date}}

  # Compile the data in format for all dates in requested start_date to end_data
  # { mid: { date: { sales: 0 }, days_live: 0 } }
  # Eg: { "Spar01203012": { "2016-01-01": { sales: 20 }, days_live: 10 } }
  report_data = {}
  (q[:created_at]["$gte"]..q[:created_at]["$lte"]).each do |date|
    mc_data.each do |mid, mc|
      report_data[mid] ||= { machine: mid, live_date: mc[:live_date], days_live: 0 }
      report_data[mid][date] = 0
    end
  end

  pay_data.each do |d|
    # Ignore test payment data
    next if mc_data[d["_id"]["mid"]].blank?
    mid = d["_id"]["mid"]
    date = d["_id"]["date"]
    sales = d["sales"]
    # Handler for machine which went live, went offline, came live again
    report_data[mid] ||= { machine: mid, live_date: (report_data[mid][:live_date] rescue Date.today), days_live: 0 }
    report_data[mid][date] = d["sales"]
    report_data[mid][:days_live] = (Date.today - report_data[mid][:live_date]).to_i rescue 0
  end

  report_data.to_json
end
