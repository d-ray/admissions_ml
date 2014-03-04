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
    [:hs_gpa, :continuous, lambda {|gpa|discretize_gpa gpa}],
    [:grad_year, :unused],
    [:act_score, :discrete],
    [:sat_score, :continuous, lambda {|sat|discretize_sat sat}],
    [:app_date, :unused],
    [:visit_code, :discrete],
    [:visit_date, :unused],
    [:inquiry_code, :discrete],
    [:admit_date, :unused],  # 19  These two form the class value
    [:enrollment_date, :unused],  # 20
    [:deposit_date, :unused],
    [:fsa, :unused],
    [:et, :unused],
    [:ot, :unused],
    [:app_status, :unused],
    [:scholarships, :discrete],
    [:scholarships_bumped, :discrete],
    [:academic_index, :unused],
    [:academic_year, :unused],
    [:family_income, :continuous, lambda {|inc|discretize_income inc}],
    [:family_contribution, :continuous, lambda {|cont|discretize_contribution cont}],
    [:total_gift_aid, :continuous, lambda {|gift|discretize_gift gift}],
    [:admit_status, :discrete],
  ]

  def self.discretize_gpa (gpa)
    if gpa.nil?
      return gpa
    end
    gpa = gpa.to_f
    if gpa >= 3.5
      return "3.5..4.0"
    elsif gpa >= 3.0
      return "3.0..3.5"
    elsif gpa >= 2.5
      return "2.5..3.0"
    elsif gpa >= 2.0
      return "2.0..2.5"
    elsif gpa >= 1.5
      return "1.5..3.0"
    elsif gpa >= 1.0
      return "1.0..1.5"
    else
      return "<1.0"
    end
  end

  def self.discretize_sat (sat)
    if sat.nil?
      return sat
    end
    sat = sat.to_i
    if sat >= 1150
      return "1150..1200"
    elsif sat >= 1100
      return "1100..1150"
    elsif sat >= 1050
      return "1050..1100"
    elsif sat >= 1000
      return "1000..1050"
    elsif sat >= 950
      return "950..1000"
    elsif sat >= 900
      return "900..950"
    elsif sat >= 850
      return "850..900"
    elsif sat >= 800
      return "800..850"
    elsif sat >= 750
      return "750..800"
    elsif sat >= 700
      return "700..750"
    else
      return "<700"
    end
  end

  def self.discretize_income (inc)
    if inc.nil?
      return inc
    end
    inc = inc.to_i
    if inc >= 500000
      return ">=500000"
    elsif inc >= 200000
      return "200000..500000"
    elsif inc >= 100000
      return "100000..200000"
    elsif inc >= 50000
      return "50000..100000"
    elsif inc >= 20000
      return "20000..50000"
    else
      return "<20000"
    end
  end

  def self.discretize_contribution (cont)
    if cont.nil?
      return cont
    end
    cont = cont.to_i
    if cont >= 50000
      return ">=50000"
    elsif cont >= 20000
      return "20000..50000"
    elsif cont >= 10000
      return "10000..20000"
    elsif cont >= 5000
      return "5000..10000"
    elsif cont >= 2000
      return "2000..5000"
    else
      return "<2000"
    end
  end

  def self.discretize_gift (gift)
    if gift.nil?
      return gift
    end
    gift = gift.to_i
    if gift >= 30000
      return ">=30000"
    elsif gift >= 25000
      return "25000..30000"
    elsif gift >= 20000
      return "20000..25000"
    elsif gift >= 15000
      return "15000..20000"
    elsif gift >= 10000
      return "10000..15000"
    elsif gift >= 5000
      return "5000..10000"
    else
      return "<5000"
    end
  end

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
            next if Params[i][1] == :unused
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
        next if Params[i][1] == :unused
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
      next if Params[i][1] == :unused
      pn = Params[i][0]
      pv = instance[i]
      if Params[i][1] == :continuous
        pv = Params[i][2].call(pv)
      end
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
        next if Params[i][1] == :unused
        pn = Params[i][0]
        pv = instance[i]
        if Params[i][1] == :continuous
          pv = Params[i][2].call(pv)
        end
         # TODO: this seems to cause a lot of floating-point inaccuracy.
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
