require 'string'
require 'parser/type'
require 'parser/lines'
require 'contract'

module Contraction
  module Parser
    RETURN_LINE_REGEX = /^#\s*@return\s+(?<type>\[[^\]]+\])?\s*(?<message>[^{]+)?(?<contract>\{([^}]+)\})?/
    PARAM_LINE_REGEX  = /^#\s*@param\s+(?<type>\[[^\]]+\])?\s*(?<name>[^\s]+)\s+(?<message>[^{]+)?(?<contract>\{([^}]+)\})?/

    def self.parse(text, mod, method_name)
      lines = text.is_a?(String) ? text.split(/$/) : text
      results = []
      lines.each do |line|
        line.strip!
        break unless line.start_with? '#'
        break if line.start_with? '##'
        results << parse_line(line.strip)
      end
      results.compact!

      Contract.new(results, mod, method_name)
    end

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
