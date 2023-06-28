# Write the routes for handling CRUD of grades
# Allow grades to be created with subjects and subject params

# GET /grades
get '/grades' do
  Grade.all.only(:title, :descr).to_json
end

# GET /grades/:id
get '/grades/:id' do
  grade = Grade.find(params[:id])
  grade.to_json
end

# POST /grades
post '/grades' do
  data = valid_params
  grade = Grade.new(data)
  if grade.save
    grade.to_json
  else
    halt 422, grade.errors.full_messages.to_json
  end
end

# PUT /grades/:id
put '/grades/:id' do
  data = valid_params
  grade = Grade.find(params[:id])
  if grade.update(data)
    grade.to_json
  else
    halt 422, grade.errors.full_messages.to_json
  end
end

# DELETE /grades/:id
delete '/grades/:id' do
  grade = Grade.find(params[:id])
  grade.destroy
  grade.to_json
end

# Clean parameters only to allow the ones we want
def valid_params
  JSON.parse(request.body.read)
end