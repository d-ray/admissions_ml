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

  def default_class_counts
    return {no_admit: 0, admit_no_matriculate: 0, admit_matriculate: 0, _TOTAL: 0}
  end

  def learn (instance)
    class_val = instance[19].nil? ? :no_admit : instance[20].nil? ? :admit_no_matriculate : :admit_matriculate
    @class_counts[:_TOTAL] += 1
    @class_counts[class_val] += 1
    Params.each_index do |i|
      if Params[i][1] == :discrete
        p = Params[i][0]
        @counts[p] = {_TOTAL: 0} if @counts[p].nil?
        @counts[p][:_TOTAL] += 1
        @counts[p][instance[i]] = default_class_counts if @counts[p][instance[i]].nil?
        @counts[p][instance[i]][:_TOTAL] += 1
        @counts[p][instance[i]][class_val] += 1
      end
    end
  end

  def predict (instance)
    ret = {}
    for cv in @class_counts.keys
      prob = @class_counts[cv]
      Params.each_index do |i|
        if Params[i][1] == :discrete
          p = Params[i][0]
          @counts[p] = {_TOTAL: 0} if @counts[p].nil?
          @counts[p][instance[i]] = default_class_counts if @counts[p][instance[i]].nil?
          prob *= @counts[p][instance[i]][cv] / @counts[p][instance[i]][:_TOTAL]
          prob /= @counts[p][instance[i]][:_TOTAL] / @counts[p][:_TOTAL]
        end
      end
      ret[cv] = prob
    end
    return ret
  end

  def initialize(params = {})
    @counts = {}
    @class_counts = default_class_counts
    if file = params[:training_file_name]
       # counts[attr name][attr value][class] = count
      data = CSV.read(file)
      key = data.shift
      for instance in data
        learn instance
      end
    end
  end

  def print
    for p in Params
      next unless p[1] == :discrete
      p = p[0]
      for v in @counts[p].keys
        unless v == :_TOTAL
          for c in [:no_admit, :admit_no_matriculate, :admit_matriculate]
            puts "counts[#{p}][#{v}][#{c}] = #{@counts[p][v][c]}"
          end
        end
      end
    end
  end

end

if __FILE__ == $0
  NaiveBayes.new(training_file_name: 'admissions_data.csv').print
end
