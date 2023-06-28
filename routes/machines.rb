MC_EDIT_FIELDS = %w(name location pincode)
MC_FIELDS = %w(mid sim imei mode name location pincode batt nss last_ping running_avg fail_count batch_num)
LIMIT = 150

# Get all Machines
get '/machines' do
  q = {}
  LIMIT = params[:limit] if params[:limit].present?
  unless params[:status].present?
    q = {mode: Machine::MODES[:test]}
  else
    q = {mode: params[:status]}
  end
  machines = Machine.where(q).only(*MC_FIELDS).limit(LIMIT)
  machines.to_json
end

get '/machines/mids' do
  Machine.live.distinct(:mid).to_json
end

get '/machines/check' do 
  mids = params[:mids]
  mc = Machine.testing.where(mid: {"$in" => mids}).only(:mid).pluck(:mid)
  {total: mids.uniq.count, matched: mc.count, missing: mids-mc}.to_json
end

# GET /machines/last_fail
# Get last genuine failed dispense for the incoming mids
# incoming mids are in params[:mids]
get '/machines/last_fail' do
  mids = params[:mids] || []
  disps = {}
  unless mids.blank?
    Dispense.collection.aggregate([
      {"$match" => {
        "mid" => {"$in" => mids},
        "payment_id" => {"$exists" => true},
        "created_at" => {"$gt" => Time.now - 7.days},
      }},
      {"$group" => {
        "_id" => "$mid",
        "data": {"$last": '$resultData.MSG'},
      }}
    ]).to_a.map{|x| disps[x["_id"]] = x["data"]}
  end
  disps.to_json
end

# Create a new machine
post '/machines' do
  params = JSON.parse(request.body.read) rescue {}
  machine = Machine.new(
    mid: params["mid"], 
    name: params["name"], 
    imei: params["imei"], 
    location: params["location"]
  )
  if machine.save
    machine.to_json
  else
    {
      status: 422,
      errors: machine.errors
    }.to_json
  end
end

# Modify an existing machine by imei
post '/machines/:imei' do |imei|
  machine = Machine.find_by(imei: imei)
  fields = JSON.parse(request.body.read) rescue {}
  errors = {}

  # enable when modification flow is clear
  # machine.mid = fields["mid"] if fields["mid"].present?
  machine.name = fields["name"] if fields["name"].present?
  machine.location = fields["location"] if fields["location"].present?
  machine.pincode = fields["pincode"] if fields["pincode"].present?
  
  if machine.save
    return machine.to_json
  else
    errors = machine.errors
  end
  
  return  {
      status: 422,
      errors: errors
    }.to_json
end

# Code to commission machines with verification code
post '/machines/commission' do 
  data = JSON.parse(request.body.read)
  puts "got #{data}"
  com = Commission.where(name: data["name"], code: data["code"]).first
  return {error: "Invalid request or code"}.to_json if com.blank?

  com.update(mids: data["mids"])
  return com.to_json
end

# Request commissioning code for commissioning machines
get '/machines/request_comm_code' do
  code = '%06d' % rand(10 ** 6)
  comm = Commission.create(name: params[:name], code: code)
  return {status: "recvd", id: comm.id.to_s}.to_json
end

# Machine details
get '/machines/:mid' do |mid|
  machine = Machine.find_by(mid: mid)
  machine.to_json
end

# Last fail - Only works for machines with MID assigned
get '/machines/:imei/last_disp' do |mid|
  disp = Dispense.where(mid: mid).last.resultData["MSG"] rescue "Unknown"
  { status: disp }.to_json
end

get '/machines/by_qr/:pa_code' do |pa_code|
  machine = Machine.find_by(paCode: pa_code)
  machine.to_json
end

get '/machines/search/:q' do |q|
  q = params[:q]
  unless q.blank?
    machine = Machine.where("$or" => [{imei: q}, {mid: q}]).first
    machine.to_json
  else
    {
      status: 422,
      errors: ["No Search provided"]
    }.to_json
  end
end

get '/machines/statuses/:imei' do |imei|
  LIMIT = params[:limit] if params[:limit].present?
  statuses = Machine.find_by(imei: imei).statuses.
    only(:batt, :nss, :created_at).
    order(created_at: :desc).limit(LIMIT).reverse
  statuses.to_json
end

get '/machines/dispenses/:imei' do |imei|
  LIMIT = params[:limit] if params[:limit].present?
  disp = Dispense.where(imei: imei).
    only(:imei, :mid, :resultData, :created_at, :updated_at).
    order(created_at: :desc).limit(LIMIT)
  disp.map{|x| 
    {
      imei: x.imei,
      mid: x.mid,
      result: (x.resultData.values_at("MSG","PSN") rescue ["Fail", nil]),
      issued: x.created_at,
      completed: x.updated_at
    }
  }.to_json
end

get '/machines/payments/:mid' do |mid|
  payments = {} 
  LIMIT = params[:limit] if params[:limit].present?

  Payment.where(mid: mid).
    only(:status, :orderId, :txnId, :refunds, :created_at).
    order(created_at: :desc).limit(LIMIT).
    map{|x| payments[x.id.to_s] = x.as_json.merge!({dispense: nil})}

  Dispense.where(payment_id: {"$in" => payments.keys}).
    only(:imei, :resultData, :payment_id, :created_at).
    map{|x| payments[x.payment_id.to_s][:dispense] = x.resultData.values_at("MSG","PSN","device_id") rescue nil}

  payments.values.to_json
end

post '/test_dispense' do
  machine = Machine.find_by(mid: params["mid"])
  if machine.live?
    halt 500, {status: 500, message: "Cannot dispense on Live machine"}.to_json
  else
    disp = Dispense.new(imei: params["imei"], mid: params["mid"], testing: true)
    if disp.save
      return {
        status: 200,
        message: "Dispense Signaled"
      }.to_json
    else
      return {
        status: 422,
        message: "Dispense Fail",
        errors: disp.errors
      }.to_json
    end
  end
end