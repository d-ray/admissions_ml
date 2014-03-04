require 'csv'

class NaiveBayes

  Params = [
    [:id, :unused],
    [:gender, :discrete],
    [:ethnicity, :discrete],
    [:state, :unused],
    [:zip, :discrete],
    [:country, :discrete],
    [:major1, :discrete],
    [:major2, :unused],
    [:major3, :unused],
    [:hs_ceed, :discrete],
    [:hs_gpa, :continuous],
    [:grad_year, :unused],
    [:act_score, :discrete],
    [:sat_score, :continuous],
    [:app_date, :unused],
    [:visit_code, :discrete],
    [:visit_date, :unused],
    [:inquiry_code, :discrete],
    [:admit_date, :class],  # 19
    [:enrollment_date, :class],  # 20
    [:deposit_date, :unused],
    [:fsa, :unused],
    [:et, :unused],
    [:ot, :unused],
    [:app_status, :unused],
    [:scholarships, :discrete],
    [:scholarships_bumped, :discrete],
    [:academic_index, :unused],
    [:academic_year, :unused],
    [:family_income, :continuous],
    [:family_contribution, :continuous],
    [:total_gift_aid, :continuous],
    [:admit_status, :discrete],
  ]

  def initialize(params = {})
    @pvs = {}
    @cvs = {no_admit: {_TOTAL: 0.0}, admit_no_matriculate: {_TOTAL: 0.0}, admit_matriculate: {_TOTAL: 0.0}, _TOTAL: 0.0}
    instance0 = nil
    if file = params[:training_file_name]
       # counts[attr name][attr value][class] = count
      data = CSV.read(file)
      key = data.shift
      for instance in data
        learn instance
      end
    end
  end

  def learn (instance)
    cv = instance[19].nil? ? :no_admit : instance[20].nil? ? :admit_no_matriculate : :admit_matriculate
    @cvs[:_TOTAL] += 1.0
    @cvs[cv][:_TOTAL] += 1.0
    Params.each_index do |i|
      next unless Params[i][1] == :discrete
      pn = Params[i][0]
      pv = instance[i]
      @cvs[cv][pn] = {_TOTAL: 0.0} if @cvs[cv][pn].nil?
      @cvs[cv][pn][:_TOTAL] += 1.0
      @cvs[cv][pn][pv] = 0.0 if @cvs[cv][pn][pv].nil?
      @cvs[cv][pn][pv] += 1.0
      @pvs[pn] = {_TOTAL: 0.0} if @pvs[pn].nil?
      @pvs[pn][:_TOTAL] += 1.0
      @pvs[pn][pv] = 0.0 if @pvs[pn][pv].nil?
      @pvs[pn][pv] += 1.0
    end
  end

  def probabilities (instance)
    ret = {}
     # P(C|F...) = P(C)P(F...|C)/P(F...)
    for cv in @cvs.keys
      next if cv == :_TOTAL
      prob = @cvs[cv][:_TOTAL] / @cvs[:_TOTAL]
      Params.each_index do |i|
        next unless Params[i][1] == :discrete
        pn = Params[i][0]
        pv = instance[i]
        @cvs[cv][pn][pv] = 0.0 if @cvs[cv][pn][pv].nil?
        prob *= @cvs[cv][pn][pv] / @cvs[cv][pn][:_TOTAL]
        @pvs[pn][pv] = 0.0 if @pvs[pn][pv].nil?
        prob /= @pvs[pn][pv] / @pvs[pn][:_TOTAL]
      end
      ret[cv] = prob
    end
    return ret
  end

  def print
    for cv in @cvs.keys
      if cv == :_TOTAL
        puts "@cvs[:_TOTAL] = #{@cvs[cv]}"
      else
        puts "@cvs[:#{cv}][:_TOTAL] = #{@cvs[cv][:_TOTAL]}"
        for p in Params
          next unless p[1] == :discrete
          pn = p[0]
          for pv in @cvs[cv][pn].keys
            if pv == :_TOTAL
              puts "@cvs[:#{cv}][:#{pn}][:_TOTAL] = #{@cvs[cv][pn][:_TOTAL]}"
            else
              puts "@cvs[:#{cv}][:#{pn}][\"#{pv}\"] = #{@cvs[cv][pn][pv]}"
            end
          end
        end
      end
    end
    for p in Params
      next unless p[1] == :discrete
      pn = p[0]
      for pv in @pvs[pn].keys
        if pv == :_TOTAL
          puts "@pvs[:#{pn}][:_TOTAL] = #{@pvs[pn][:_TOTAL]}"
        else
          puts "@pvs[:#{pn}][\"#{pv}\"] = #{@pvs[pn][pv]}"
        end
      end
    end
  end

end

if __FILE__ == $0
  NaiveBayes.new(training_file_name: 'admissions_data.csv').print
end
