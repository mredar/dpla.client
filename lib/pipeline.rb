require 'open-uri'
require 'rest_client'

class Pipeline
  include ImportLog

  def initialize(profile)
    @profile = JSON.parse(profile)
    self
  end

  def extraction
    fetch_remote_data(@profile['extractor']['records'])
  end

  def enrichments
    fetch_enrichments(@profile['extractor']['record_enrichments'])
  end

  def transform(extraction, enrichments)
    if extraction
      begin
        import_log.info("Transformer: attmpting to post profile data #{@profile['transformer']['base_url']} with access token #{@profile['transformer']['api_key']}")
        resource = RestClient::Resource.new(@profile['transformer']['base_url'],
          :timeout => 600,
          :open_timeout => 60,
          :content_type => :json,
          :accept => :json
        )
        records = resource.post(
            {
              :profile => @profile.to_json,
              :records => extraction.to_json,
              :enrichments => enrichments.to_json,
              :api_key => @profile['transformer']['api_key']
            }
          )
      rescue => e
        import_log.error("Transformer: I give up. Transformer at #{@profile['transformer']['base_url']} is not responding in time.")
        raise e
      end
    end
  end

  def compare_with_dpla(record, dpla_query_params)
    begin
      resource = RestClient::Resource.new("#{@profile['validator']['base_url']}/diff",
        :timeout => 30,
        :open_timeout => 60,
        :content_type => :json,
        :accept => :json
      )
      validation = resource.post(
          {
            :record => record.to_json,
            :api_key => @profile['validator']['api_key'],
            :dpla_api_key => @profile['validator']['dpla_api_key'],
            :dpla_query_params => dpla_query_params
          }
        )
    rescue => e
      import_log.error("Validator: I give up. Validator at #{@profile['validator']['base_url']} is not responding in time.")
      raise e
    end
  end

  def fetch_remote_data(params)
    data = nil
    url = construct_url(params)
    begin
      import_log.info("Attempting to fetch data for #{url}")
      open(url, :read_timeout=> 120) { |d|
        data = d.read
      }
    rescue => e
      import_log.error("Extractor: I give up, we failed to fetch data for #{url}")
    end
    if (data.nil?)
      import_log.error("Extractor: Failed to fetch remote data for url: #{url}")
      raise e
    end
    data
  end

  def fetch_enrichments(enrich_extractions)
    enrichments = []
    enrich_extractions.each do |enrich|
      # parse the response so that we can add in some extra metadata
      data = fetch_remote_data(enrich['extract'])
      enrichment = JSON.parse(data)
      enrichments << { 'transform' => enrich['transform'], 'enrichment' => enrichment }
    end
    # now convert the whole thing to JSON, which is what the transformer expects
    enrichments.to_json
  end

  def construct_url(params)
    # Tack on the next iterrator
    query = "&query_params=#{params['query_params']}"
    cache_response = (params['cache_response']) ? "&cache_response=#{params['cache_response']}" : nil
    batch_param = (defined?(params['batch_param']) && !params['batch_param'].nil?) ? "&batch_param=#{params['batch_param']}" : nil
    "#{params['base_url']}?endpoint=#{params['endpoint']}&endpoint_type=#{params['endpoint_type']}&api_key=#{params['api_key']}#{query}#{batch_param}#{cache_response}"
  end
end