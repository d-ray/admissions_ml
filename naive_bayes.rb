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

  def train (instance)
    class_val = instance[19].nil? ? :no_admit : instance[20].nil? ? :admit_no_matriculate : :admit_matriculate
    Params.each_index do |i|
      if Params[i][1] == :discrete
        p = Params[i][0]
        if @counts[p].nil? then @counts[p] = {} end
        if @counts[p][instance[i]].nil? then @counts[p][instance[i]] = {} end
        if @counts[p][instance[i]][class_val].nil? then @counts[p][instance[i]][class_val] = 0 end
        @counts[p][instance[i]][class_val] += 1
      end
    end
  end

  def initialize(params = {})
    @counts = {}
    if file = params[:training_file_name]
       # counts[attr name][attr value][class] = count
      data = CSV.read(file)
      key = data.shift
      for instance in data
        train instance
      end
    end
  end

  def print
    for p in Params
      next unless p[1] == :discrete
      p = p[0]
      for v in @counts[p].keys
        unless @counts[p][v].nil?
          for c in [:no_admit, :admit_no_matriculate, :admit_matriculate]
            if @counts[p][v][c].nil? then @counts[p][v][c] = 0 end
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
