require 'string'
require 'parser/type'
require 'parser/lines'
require 'parser/type_parser'
require 'contract'

module Contraction
  module Parser
    RETURN_LINE_REGEX = /^#\s*@return\s+(?<type>\[[^\]]+\])?\s*(?<message>[^{]+)?(?<contract>\{([^}]+)\})?/
    PARAM_LINE_REGEX  = /^#\s*@param\s+(?<type>\[[^\]]+\])?\s*(?<name>[^\s]+)\s+(?<message>[^{]+)?(?<contract>\{([^}]+)\})?/

    # Parses text passed to it for a given method for RDoc @param and @return
    # lines to build contracts.
    # @param [Array,String] text The text to be parsed.
    # @param [Class,Module] mod The class or module that the method is defined
    # in.
    # @param [Symbol,String] method_name The name of the method that the
    # contracts/docs apply to
    # @return [Contract] A Contract object that can be used to evaluate
    # correctness at run-time.
    def self.parse(text, mod, method_name, type)
      lines = text.is_a?(String) ? text.split(/$/) : text
      results = []
      lines.each do |line|
        line.strip!
        break unless line.start_with? '#'
        break if line.start_with? '##'
        results << parse_line(line.strip)
      end
      results.compact!

      Contract.new(results, mod, method_name, type)
    end

    # Parse a single line of text for @param and @return statements.
    # @param [String] line The line of text to parse
    # @return [TypedLine] An object that represents the parsed line including
    # type information and contract.
    def self.parse_line(line)
      if m = line.match(PARAM_LINE_REGEX)
        args = {
          type: m['type'].to_s.gsub(/(\[|\])/, ''),
          name: m['name'],
          message: m['message'],
          contract: (m['contract'] || 'true').gsub(/(^\{)|(\}$)/, '')
        }
        return ParamLine.new(args)
      elsif m = line.match(RETURN_LINE_REGEX)
        args = {
          type: m['type'].to_s.gsub(/(\[|\])/, ''),
          message: m['message'],
          contract: (m['contract'] || 'true').gsub(/(^\{)|(\}$)/, '')
        }
        return ReturnLine.new(args)
      end
    end
  end
end
