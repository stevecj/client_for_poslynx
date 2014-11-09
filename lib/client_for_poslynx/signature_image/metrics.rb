module ClientForPoslynx
  class SignatureImage

    class Metrics <
      Struct.new(

        # [x,y] scaled resolution
        :resolution,

        # [x,y] pysical size in dekamicrometers
        # 1 dekamicrometer = 10 micrometers or 0.01 millimeters
        :size_in_dum,
      )
    end

  end
end
