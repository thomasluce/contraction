require 'string'
require 'parser/type'
require 'parser/lines'

module Contraction
  module Parser
    RETURN_LINE_REGEX = /^#\s*@return\s+(?<type>\[[^\]]+\])?\s*(?<message>[^{]+)?(?<contract>\{([^}]+)\})?/
    PARAM_LINE_REGEX  = /^#\s*@param\s+(?<type>\[[^\]]+\])?\s*(?<name>[^\s]+)\s+(?<message>[^{]+)?(?<contract>\{([^}]+)\})?/

    def self.parse(line)
      if m = line.match(PARAM_LINE_REGEX)
        args = {
          type: m['type'].to_s.gsub(/(\[|\])/, ''),
          name: m['name'],
          message: m['message'],
          contract: (m['contract'] || 'true').gsub(/(^\{)|(\}$)/, '')
        }

        return ParamLine.new(args)
      else
        raise 'Should not be here'
      end
    end
  end
end
