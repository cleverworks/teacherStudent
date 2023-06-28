# Write the routes for handling CRUD of chapters
# Allow chapters to be created with subjects and subject params

# GET /chapters
get '/chapters' do
  Chapter.all.only(:title, :descr).to_json
end

# GET /chapters/:id
get '/chapters/:id' do
  chapter = Chapter.find(params[:id])
  chapter.to_json
end

# POST /chapters
post '/chapters' do
  data = valid_params
  binding.pry
  chapter = Chapter.new(data)
  if chapter.save
    chapter.to_json
  else
    halt 422, chapter.errors.full_messages.to_json
  end
end

# PUT /chapters/:id
put '/chapters/:id' do
  data = valid_params
  chapter = Chapter.find(params[:id])
  if chapter.update(data)
    chapter.to_json
  else
    halt 422, chapter.errors.full_messages.to_json
  end
end

# DELETE /chapters/:id
delete '/chapters/:id' do
  chapter = Chapter.find(params[:id])
  chapter.destroy
  chapter.to_json
end

# Clean parameters only to allow the ones we want
def valid_params
  JSON.parse(request.body.read)
end