module Helpers
  def ordinalize(number)
    if (11..13).include?(number.to_i % 100)
      "#{number}th"
    else
      case number.to_i % 10
        when 1 then "#{number}st"
        when 2 then "#{number}nd"
        when 3 then "#{number}rd"
        else "#{number}th"
      end
    end
  end
  
  def escape(s)
    s.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/n) {
      '%'+$1.unpack('H2'*$1.size).join('%').upcase
    }.tr(' ', '+')
  end
end

class Stone::Renderer
  include(Helpers)
end