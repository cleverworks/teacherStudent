# Write the routes for handling CRUD of subjects
# Allow subjects to be created with subjects and subject params

# GET /subjects
get '/subjects' do
  Subject.all.to_json
end

# GET /subjects/:id
get '/subjects/:id' do
  subject = Subject.find(params[:id])
  subject.to_json
end

# POST /subjects
post '/subjects' do
  data = valid_params
  subject = Subject.new(data)
  if subject.save
    subject.to_json
  else
    halt 422, subject.errors.full_messages.to_json
  end
end

# PUT /subjects/:id
put '/subjects/:id' do
  data = valid_params
  subject = Subject.find(params[:id])
  if subject.update(data)
    subject.to_json
  else
    halt 422, subject.errors.full_messages.to_json
  end
end

# DELETE /subjects/:id
delete '/subjects/:id' do
  subject = Subject.find(params[:id])
  subject.destroy
  subject.to_json
end

# Clean parameters only to allow the ones we want
def valid_params
  JSON.parse(request.body.read)
end