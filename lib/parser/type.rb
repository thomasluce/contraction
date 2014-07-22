module Contraction
  module Parser
    class Type
      attr_reader :type
      def initialize(part)
        parse(part)
      end

      # Checks weather or not thing is a given type.
      def check(thing)
        return true unless type
        type.check thing
      end

      private

      def parse(line)
        @type = Contraction::TypeParser.parse(line).first
      rescue => e
        puts e
        @type = nil
      end
    end
  end
end
