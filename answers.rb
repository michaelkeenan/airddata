
def save_answers
  json = JSON.parse(request.body.read)
  uuid = escape_html(json['uuid'])
  answers = json['answers']
  @answers_store.transaction do
    @answers_store[uuid] = answers
  end
end

def aggregate_answers
  agg_answers = Hash.new(0)
  @answers_store.transaction do
    @answers_store.roots.each do |root|
      answer_set = JSON.parse(@answers_store[root])
      answer_set.keys.each do |url|
        agg_answers["#{url}|#{answer_set[url]}"] += 1
      end
    end
  end
  agg_answers
end

def urls_from_aggregate_answers(aggregate_answers)
  aggregate_answers.keys.map { |url_agreement| url_agreement.split('|').first }.uniq
end

def answers
  @answers = {}
  @answers_store.transaction do
    @answers_store.roots.each do |root|
      @answers[root] = JSON.parse(@answers_store[root])
    end
  end
  @aggregate_answers = aggregate_answers
  @urls = urls_from_aggregate_answers(@aggregate_answers)
  @root_arguments = ['the-alignment-problem', 'instrumental-incentives', 'threat-models', 'pursuing-safety-work']
  @root_argument_titles = [
    'The Alignment Problem',
    'Instrumental Incentives',
    'Threat Models',
    'Pursuing Safety Work'
  ]
end

options '/answers' do
  allow_cors_options
end

options '/answers/json' do
  allow_cors_options
end

post "/answers" do
  headers['Access-Control-Allow-Origin'] = '*'
  save_answers
  "OK"
end

get '/answers/json' do
  content_type :json
  headers['Access-Control-Allow-Origin'] = '*'
  answers
  erb :answers_json, layout: nil
end

get "/answers" do
  answers
  erb :answers
end
