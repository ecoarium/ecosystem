
module TerminalHelper
	module AskMixin

    def self.included(receiver)
      receiver.send :include, AskMethods
    end

    def self.extended(receiver)
      receiver.extend         AskMethods
    end

    module AskMethods

      def ask_for_input(message)
        puts message
        $stdin.gets.chomp
      end

      def ask_for_sensative_input(message)
        puts message
        $stdin.noecho(&:gets).chomp
      end

      def ask_with_options(message, options)
        input = nil
        until (1..options.length).to_a.include?(input.to_i)
          puts message

          options.each_with_index{|option, index|
          	puts "  #{index + 1}.\t#{option}"
          }

          puts "(Enter 1-#{options.length}): "
          input = $stdin.gets.chomp
        end

        options[input.to_i - 1]
      end

			def ask_with_options_and_default(message, options)
				input = nil
				puts message

				options.each_with_index{|option, index|
					puts "  #{index + 1}.\t#{option}"
				}

				puts "(Enter 1-#{options.length}): "
				input = $stdin.gets.chomp
				if input.to_s == ''
					input = options[0]
				else
					input = options[input.to_i - 1]
				end
				input
			end


      def ask_confirm(message)
        puts message
        puts "Enter \"Y/y\" to confirm."
        input = $stdin.gets.chomp
				input == "Y" || input == "y"
      end

    end
  end

  class Ask
    extend TerminalHelper::AskMixin::AskMethods
  end
end
