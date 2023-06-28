#TODO fix this
PAYMENT_FIELDS = ["amount","txnId","orderId","mid","status","txnType","created_at", "dispensed", "refunded","txnData.BANKTXNID"]
REF_STATUS = {
  "600" => "Not processed by Bank",
  "601" => "Refund Initiated",
  "631" => "Invalid refund",
  "620" => "Balance Insufficient"
}

['/payments', '/refunds'].each do |path|
  get path do
    q = {created_at: {"$gte" => Date.today - 7.days}}
    q[:mid] = params[:mid] if params[:mid].present?
    q[:refunds] = {"$ne" => nil} if path == "/refunds"
    q[:created_at]["$gte"] = Date.parse(params[:start_date]).beginning_of_day if params[:start_date].present?
    q[:created_at]["$lte"] = Date.parse(params[:end_date]).end_of_day if params[:end_date].present?
    limit = (q[:created_at]["$lte"].present? rescue false) ? 1000 : 100
    payments = Payment.where(q).order(created_at: :desc).only(*PAYMENT_FIELDS).limit(limit)
    if path == "/refunds"
      dispenses = {}
      Dispense.where(payment_id: {"$in" => payments.map(&:id)}).only(:status, "resultData.MSG", :payment_id).
        map{|x| dispenses[x.payment_id.to_s] = {result: (x.resultData["MSG"] rescue "TIMEOUT"), dstatus: x.status}}
      payments = payments.map{|x| x.as_json.merge!(dispenses[x.id.to_s]) rescue x.as_json }
    end
    payments.to_json
  end
end

[ '/payments/:txnId', '/refunds/:txnId' ].each do |path|
  get path do |txnId|
    payment = Payment.find_by(txnId: txnId)
    ref_data = payment.refunds.map{|x| {
      reason: x.reason,
      created_at: x.created_at,
      refundTnxId: x.refundTnxId,
      refundData: (REF_STATUS[x.refundData["body"]["resultInfo"]["resultCode"]] rescue "Unknown"),
      result: (x.resultInfo["resultMsg"] rescue "Confirmation Pending")
    }}
    payment.attributes.slice("amount","txnId","orderId","mid","status","txnType","created_at").merge(
      refunds: ref_data,
      dispenses: payment.dispenses.only(:status, "resultData.MSG", :created_at)
    ).to_json
  end
end

get '/payment_stats' do
  # Take last 1000 genuine payments
  res = Payment.where(status: "TXN_SUCCESS", paySignature: true).
    order(created_at: :desc).
    only(:refunded).
    limit(1000).group_by{|x| x.refunded}

  counts = {total: 0, success: 0, failures: 0}

  # Get stats for the latest 100 failures encountered
  Payment.where(status: "TXN_SUCCESS", paySignature: true).order(created_at: :desc).
    limit(2000).only(:dispensed).each do |x|
    counts[:total] += 1
    x.dispensed? ? counts[:success] += 1: counts[:failures]+=1;
    break if counts[:failures] == 100
  end
  {overall: {success: res[false].count, failures: res[true].count}}.merge!(counts).to_json
end


get '/refund_expired' do
  res = Payment.refund_expired
  {
    message: res
  }.to_json
end