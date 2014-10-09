module Normdist
  def normdist(z)
    sign = 1
    sign = -1 if z < 0
    0.5 * (1.0 + sign * erf(z.abs / Math.sqrt(2)))
  end

  # fractional error less than 1.2 * 10 ^ -7.
  def erf(z)
    t = 1.0 / (1.0 + 0.5 * z.abs)

    # use Horner's method
    ans = 1 - t * Math.exp(-z * z - 1.26551223 +
    t * (1.00002368 +
    t * (0.37409196 +
    t * (0.09678418 +
    t * (-0.18628806 +
    t * (0.27886807 +
    t * (-1.13520398 +
    t * (1.48851587 +
    t * (-0.82215223 +
    t * (0.17087277))))))))))
    z >= 0 ? ans : -ans
  end
end
