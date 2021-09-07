module Intrigue
  module Task
    module RedirectChain
      include Intrigue::Task::Web

      def find_and_log_excessive_redirects(responses)
        redirect_complete_chain = []
        redirect_total_count = 0

        # iterate through responses
        begin
          max_redirect_count = Intrigue::Core::System::Config.config['redirect_issue_trigger_count']

          max_redirect_count = 10 if max_redirect_count.nil? || max_redirect_count.to_s.empty?

          _log_debug "Max redirect count: #{max_redirect_count}"

          responses.each do |r|
            next unless r

            temp = []
            # this is to fix the ordering when saving to the DB.
            # If we change ident to return the hash props as "source" and "destination".
            # We can then remove this code.
            r[:redirect_chain].each do |x|
              temp << {
                'source' => x[:from].to_s,
                'destination' => x[:to].to_s
              }
            end

            r[:redirect_chain] = temp

            redirect_complete_chain.append(r[:redirect_chain]) unless r[:redirect_chain].empty?
            
            redirect_total_count += r[:redirect_count]

            # raise an issue when a response redirected more than the max redirect count.

            if r[:redirect_count] > max_redirect_count
              _create_execessive_redirects_issue(hostname, r[:redirect_chain], r[:redirect_count])
            end
          end
        rescue StandardError => e
          _log_error "Unable to fetch redirect chain: #{e}"
        end

        {
          chain: redirect_complete_chain,
          count: redirect_total_count
        }
      end
    end
  end
end