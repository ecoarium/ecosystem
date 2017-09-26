
module DeepJoin

  def deep_join(opts={})
    opts = {
      key_value_separator: ':',
      line_separator: '* ', 
      line_separator_extention: '  ',
      complex_prefix: ' --'
    }.merge(opts)

    key_value_separator = opts[:key_value_separator]
    line_separator = opts[:line_separator]
    line_separator_extention = opts[:line_separator_extention]
    complex_prefix = opts[:complex_prefix]

    
    joined = StringIO.new

    each_with_index {|item, index|
      joined.write "#{line_separator_extention}#{line_separator}"

      if self.class == Array and item.class == Hash
        joined.puts complex_prefix
        joined.write item.deep_join(
            key_value_separator: key_value_separator,
            line_separator: line_separator,
            line_separator_extention: "#{line_separator_extention}#{line_separator_extention}",
            complex_prefix: complex_prefix
          )
      elsif self.class == Array and item.class == Array
        joined.puts complex_prefix
        joined.write item.deep_join(
            key_value_separator: key_value_separator,
            line_separator: line_separator,
            line_separator_extention: "#{line_separator_extention}#{line_separator_extention}",
            complex_prefix: complex_prefix
          )
      elsif item.is_a?(Array)
        key = item[0]
        value = item[1]

        joined.write "#{key}"

        if value.respond_to?(:deep_join)
          joined.puts complex_prefix
          joined.write value.deep_join(
            key_value_separator: key_value_separator,
            line_separator: line_separator,
            line_separator_extention: "#{line_separator_extention}#{line_separator_extention}",
            complex_prefix: complex_prefix
          )
        elsif self.is_a?(Array) and !value.respond_to?(:deep_join)
          joined.puts "#{line_separator_extention}#{line_separator}#{value}#{key_value_separator}"
        elsif self.is_a?(Hash) and !value.respond_to?(:deep_join)
          joined.puts "#{key_value_separator}#{value}"
        else
          joined.puts "#{key_value_separator}#{value}"
        end
      else
        joined.puts item
      end
    }

    joined.string
  end
end