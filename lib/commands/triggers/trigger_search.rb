module TohsakaBot
  module Commands
    module TriggerSearch
      extend Discordrb::Commands::CommandContainer
      command(:triggersearch,
              aliases: %i[searchtrigger tsearch ts],
              description: 'Search triggers.',
              usage: 'triggersearch --t(rigger) <trigger msg> --a(uthor) <id|mention> --r(esponse) <response msg>',
              min_args: 1,
              require_register: true,
              rescue: "`%exception%`") do |event, *msg|

        args = msg.join(' ')
        options = {}

        OptionParser.new do |opts|
          opts.on('--author USER_ID', String)
          opts.on('--trigger PHRASE', String)
          opts.on('--response RESPONSE', String)
        end.parse!(Shellwords.shellsplit(args), into: options)

        result = TohsakaBot.trigger_data.full_triggers.select do |k, v|

          if options[:author].nil?
            opt_author = v.user
          elsif !Integer(options[:author], exception: false)
            opt_author = options[:author].gsub(/[^\d]/, '')
          else
            opt_author = options[:author]
          end

          if options[:author].nil? && options[:trigger].nil? && options[:response].nil?
            opt_trigger = args
            opt_response = args

            v.user.to_i == opt_author.to_i && (v.phrase.to_s.include?(opt_trigger.to_s) || v.reply.to_s.include?(opt_response.to_s))
          else
            opt_trigger = options[:trigger].nil? ? v.phrase : options[:trigger]
            opt_response = options[:response].nil? ? v.reply : options[:response]

            v.user.to_i == opt_author.to_i && v.phrase.to_s.include?(opt_trigger.to_s) && v.reply.to_s.include?(opt_response.to_s)
          end
        end

        result_amount = 0
        sorted = result.sort_by { |k| k }
        output = "`Modes include normal (0), any (1) and regex (2).`\n`  ID | M & % | TRIGGER                           | MSG/FILE`\n"
        sorted.each do |k, v|
          if v.reply.nil?
            output << "`#{sprintf("%4s", k)} | #{sprintf("%-5s", v.mode.to_s + " " + v.chance.to_s)} | #{sprintf("%-33s", v.phrase.to_s.gsub("\n", '')[0..30])} | #{sprintf("%-21s", v.file[0..20])}`\n"
          else
            output << "`#{sprintf("%4s", k)} | #{sprintf("%-5s", v.mode.to_s + " " + v.chance.to_s)} | #{sprintf("%-33s", v.phrase.to_s.gsub("\n", '')[0..30])} | #{sprintf("%-21s", v.reply.gsub("\n", '')[0..20])}`\n"
          end
          result_amount += 1
        end

        where = result_amount > 5 ? event.author.pm : event.channel

        if result.any?
          where.split_send "#{output}"
        else
          event.<< 'No triggers found.'
        end
      end
    end
  end
end