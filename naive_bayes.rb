require 'csv' 
class NaiveBayes

  Config_Folder = "config"
  Training_Data_Folder = "training_data"
  Test_Data_Folder = "test_data"

  def initialize (params = {})
    @param_values = {}
    @class_values = {"no_admit" => {"_TOTAL" => 0.0}, "admit_no_matriculate" => {"_TOTAL" => 0.0}, "admit_matriculate" => {"_TOTAL" => 0.0}, "_TOTAL" => 0.0}
    if file = params[:training_file_name]
      @training_data = []
      File.open("#{Training_Data_Folder}/#{params[:training_file_name]}") do |f|
        @params = f.gets.split(',') # read param names from header
        f.each_line do |line|
          instance = line.chomp.split(/[,:]/)
          class_value = instance.delete_at(instance.size - 1)
          @training_data << [instance, class_value]
        end
        if false # TODO is discrete
          for class_value in @class_values.keys
            for param_name in @param_values.keys
              sum = 0.0
              for param_value in @class_values[class_value][param_name].keys
                @class_values[class_value][param_name][param_value].times do
                  sum += param_value.to_f
                end
              end
              mean = sum / @class_values[class_value][param_name]['_TOTAL']
              variance = @class_values[class_value][param_name].map{|v|
                r = v - mean
                return r * r
              }.inject(0, :+)
              @class_values[class_value][param_name] = {'_MEAN' => mean, '_VARIANCE' => variance}
            end
          end
        end
      end
    elsif file = params[:config_file_name]
      config_data = CSV.read("#{Config_Folder}/#{file}")
      for row in config_data
        class_value = row[0]
        param_name = row[1]
        param_value = row[2]
        value = row[3].to_f
        if class_value == "_TOTAL"
          if param_name == "_TOTAL"
            @class_values["_TOTAL"] = value
          else
            @param_values[param_name] = {} if @param_values[param_name].nil?
            @param_values[param_name][param_value] = value
          end
        else
          if param_name == "_TOTAL"
            @class_values[class_value]["_TOTAL"] = value
          else
            @class_values[class_value][param_name] = {} if @class_values[class_value][param_name].nil?
            @class_values[class_value][param_name][param_value] = value
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

  def train_and_save (config_file_name = "nb_config.csv")
    train
    CSV.open("#{Config_Folder}/#{config_file_name}", "w") do |csv|
      for class_value in @class_values.keys
        if class_value == "_TOTAL"
          csv << ['_TOTAL', '_TOTAL', '_TOTAL', @class_values[class_value]]
        else
          csv << [class_value.to_s, '_TOTAL', '_TOTAL', @class_values[class_value]["_TOTAL"]]
          @params.each do |param_name|
            for param_value in @class_values[class_value][param_name].keys
              csv << [class_value.to_s, param_name, param_value, @class_values[class_value][param_name][param_value]]
            end
          end
        end
      end
      @params.each do |param_name|
        for param_value in @param_values[param_name].keys
          csv << ['_TOTAL', param_name.to_s, param_value, @param_values[param_name][param_value]]
        end
      end
    end
  end

  def learn (instance)
    class_value = instance.last
    @class_values["_TOTAL"] += 1.0
    @class_values[class_value]["_TOTAL"] += 1.0
    @params.each_with_index do |param_name, i|
      param_value = instance.first[i]
      @class_values[class_value][param_name] = {'_TOTAL' => 0.0} if @class_values[class_value][param_name].nil?
      @class_values[class_value][param_name]["_TOTAL"] += 1.0
      @class_values[class_value][param_name][param_value] = 0.0 if @class_values[class_value][param_name][param_value].nil?
      @class_values[class_value][param_name][param_value] += 1.0
      if true # TODO is NOT discrete
        @param_values[param_name] = {'_TOTAL' => 0.0} if @param_values[param_name].nil?
        @param_values[param_name]["_TOTAL"] += 1.0
        @param_values[param_name][param_value] = 0.0 if @param_values[param_name][param_value].nil?
        @param_values[param_name][param_value] += 1.0
      end
    end
  end

  def probabilities (instance)
    ret = {}
     # P(C|F...) = P(C)P(F...|C)/P(F...)
    for class_value in @class_values.keys
      next if class_value == "_TOTAL"
      prob = @class_values[class_value]["_TOTAL"] / @class_values["_TOTAL"]
      @params.each_with_index do |param_name, i|
        param_value = instance[i]
        if false # TODO is discrete
            # TODO I'm not sure this is correct by itself.  Do we have to divide by the total like below?
          prob *= NaiveBayes.density_at(@class_values[class_value][param_name]['_MEAN'].to_f, @class_values[class_value][param_name]['_VARIANCE'].to_f, param_value)
        else
           # TODO: this seems to cause a lot of floating-point inaccuracy.
          @class_values[class_value][param_name][param_value] = 0.0 if @class_values[class_value][param_name][param_value].nil?
          prob *= (@class_values[class_value][param_name][param_value]+1) / (@class_values[class_value][param_name]["_TOTAL"]+1)
          @param_values[param_name][param_value] = 0.0 if @param_values[param_name][param_value].nil?
          prob /= (@param_values[param_name][param_value]+1) / (@param_values[param_name]["_TOTAL"]+1)
        end
      end
      if prob != prob
        puts "Instance led to NAN result: #{instance.inspect}"
      end
      ret[class_value] = prob
    end
    return ret
  end

  def predict (instance)
    probs = probabilities instance
    max_class_value = nil
    max_prob = 0.0
    for class_value in probs.keys
      if probs[class_value] > max_prob
        max_prob = probs[class_value]
        max_class_value = class_value
      end
    end
    return max_class_value
  end

  def rate_accuracy(test_file_name = "nb_test_data.txt")
    test_data = []
    File.open("#{Test_Data_Folder}/#{test_file_name}") do |f|
      @params = f.gets.split(',') # reader param names from header
      f.each_line do |line|
        test_data << line.chomp.split(/[,:]/)
      end
    end

    classification_counts = {}
    test_data.each do |instance|
      class_value = instance.delete_at(instance.size - 1)
      classification_counts[class_value] ||= {correct: 0, total: 0}
      classification_counts[class_value][:total] += 1
      classification_counts[class_value][:correct] += 1 if (self.predict(instance) == class_value)
    end

    total_correct = 0 
    classification_counts.values.each {|h| total_correct += h[:correct]}
    puts "Total: #{total_correct} out of #{test_data.size} (#{(total_correct.to_f / test_data.size) * 100}%) correctly classified"
    puts "By class value:"
    classification_counts.each {|kv_pair| puts "Value #{kv_pair.first}: #{kv_pair.last[:correct]} out of #{kv_pair.last[:total]} (#{(kv_pair.last[:correct].to_f / kv_pair.last[:total]) * 100}%) correctly classified"}
  end

  def self.density_at (mean, variance, value)
    1/Math.sqrt(2*Math::PI*variance) * Math.exp(-((value-mean)*(value-mean))/(2 * variance))
  end

end

NaiveBayes.new(training_file_name: "nb_train_by_year.txt").train_and_save
nb = NaiveBayes.new(config_file_name: "nb_config.csv")
nb.rate_accuracy("nb_test_by_year.txt")

#if __FILE__ == $0
#  NaiveBayes.new(training_file_name: 'admissions_data.csv').train_and_save('nb_config.csv')
#end
