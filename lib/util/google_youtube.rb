require 'google/api_client'

class GoogleYoutube
    def initialize(api_key)
        @client = Google::APIClient.new(
            :key => api_key,
            :authorization => nil,
            :application_name => 'ElFari',
            :application_version => '1.0.0'
        )
        @youtube = @client.discovered_api('youtube', 'v3')
    end

    def get_video(query)
        begin
            res = @client.execute!(
                :api_method => @youtube.search.list,
                :parameters => {
                    :part => 'snippet',
                    :type => 'video',
                    :maxResults => 1,
                    :q => query
                }
            )

            if res.data.items.any?
                video = res.data.items[0]
                uri = "https://www.youtube.com/watch?v=#{video.id.videoId}"
                title = video.snippet.title
                content_details = get_content_details(video.id.videoId)
                return uri, title, parse_duration(content_details.duration)
            else
                return nil, nil, nil
            end
        rescue Google::APIClient::TransmissionError => ex
            puts ex.result.body
            return nil, nil, nil
        end
    end

    def get_content_details(video_id)
        details = @client.execute!(
            :api_method => @youtube.videos.list,
            :parameters => {
                :part => 'contentDetails',
                :id => video_id
            }
        )
        return details.data.items[0].contentDetails
    end

    def parse_duration(duration)
        minutes = /(\d+)M/.match(duration)[1]
        seconds = /(\d+)S/.match(duration)[1]
        return "00:#{minutes.rjust(2, '0')}:#{seconds.rjust(2, '0')}"
    end
end
