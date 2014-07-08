require 'string'
require 'parser/type'
require 'parser/lines'
require 'parser/contract'

module Contraction
  module Parser
    RETURN_LINE_REGEX = /^#\s*@return\s+(?<type>\[[^\]]+\])?\s*(?<message>[^{]+)?(?<contract>\{([^}]+)\})?/
    PARAM_LINE_REGEX  = /^#\s*@param\s+(?<type>\[[^\]]+\])?\s*(?<name>[^\s]+)\s+(?<message>[^{]+)?(?<contract>\{([^}]+)\})?/

    def self.parse(text, mod)
      results = text.split(/$/).map do |line|
        parse_line(line)
      end

      Contract.new(results, mod)
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
          name: m['name'],
          contract: (m['contract'] || 'true').gsub(/(^\{)|(\}$)/, '')
        }
        return ReturnLine.new(args)
      end
      # The else-case here doesn't really matter.
    end
  end
end
