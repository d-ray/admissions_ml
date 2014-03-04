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

  def initialize (params = {})
    @pvs = {}
    @cvs = {no_admit: {_TOTAL: 0.0}, admit_no_matriculate: {_TOTAL: 0.0}, admit_matriculate: {_TOTAL: 0.0}, _TOTAL: 0.0}
    if file = params[:training_file_name]
      @training_data = CSV.read(file)
      key = @training_data.shift
    elsif file = params[:config_file_name]
      config_data = CSV.read(file)
      for row in config_data
        cv = row[0].to_sym
        pn = row[1].to_sym
        pv = row[2]
        value = row[3].to_f
        if cv == :_TOTAL
          if pn == :_TOTAL
            @cvs[:_TOTAL] = value
          else
            @pvs[pn] = {} if @pvs[pn].nil?
            if pv == '_TOTAL'
              @pvs[pn][:_TOTAL] = value
            else
              @pvs[pn][pv] = value
            end
          end
        else
          if pn == :_TOTAL
            @cvs[cv][:_TOTAL] = value
          else
            @cvs[cv][pn] = {} if @cvs[cv][pn].nil?
            if pv == '_TOTAL'
              @cvs[cv][pn][:_TOTAL] = value
            else
              @cvs[cv][pn][pv] = value
            end
          end
        end
      end
    end
  end

  def train
    for instance in @training_data
      learn instance
    end
  end

  def train_and_save (config_file_name)
    train
    CSV.open(config_file_name, "w") do |csv|
      for cv in @cvs.keys
        if cv == :_TOTAL
          csv << ['_TOTAL', '_TOTAL', '_TOTAL', @cvs[cv]]
        else
          csv << [cv.to_s, '_TOTAL', '_TOTAL', @cvs[cv][:_TOTAL]]
          Params.each_index do |i|
            next unless Params[i][1] == :discrete
            pn = Params[i][0]
            for pv in @cvs[cv][pn].keys
              if pv == :_TOTAL
                csv << [cv.to_s, pn.to_s, '_TOTAL', @cvs[cv][pn][pv]]
              else
                csv << [cv.to_s, pn.to_s, pv, @cvs[cv][pn][pv]]
              end
            end
          end
        end
      end
      Params.each_index do |i|
        next unless Params[i][1] == :discrete
        pn = Params[i][0]
        for pv in @pvs[pn].keys
          if pv == :_TOTAL
            csv << ['_TOTAL', pn.to_s, '_TOTAL', @pvs[pn][pv]]
          else
            csv << ['_TOTAL', pn.to_s, pv, @pvs[pn][pv]]
          end
        end
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

  def predict (instance)
    probs = probabilities instance
    max_cv = nil
    max_prob = 0.0
    for cv in probs.keys
      if probs[cv] > max_prob
        max_prob = probs[cv]
        max_cv = cv
      end
    end
    return max_cv
  end

end

if __FILE__ == $0
  NaiveBayes.new(training_file_name: 'admissions_data.csv').train_and_save('nb_config.csv')
end
