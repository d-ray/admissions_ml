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
        @params = f.gets.chomp.split(',') # read param names from header
        @param_types = {}
        f.gets.chomp.split(',').each_with_index {|type, index| @param_types[@params[index]] = type} # read param types from header
        f.each_line do |line|
          instance = line.chomp.split(/[,:]/)
          class_value = instance.delete_at(instance.size - 1)
          @training_data << [instance, class_value]
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

    for param_name in @params
      if @param_types[param_name] == "continuous"
        for class_value in @class_values.keys
          next if class_value == "_TOTAL"
          sum = 0.0
          variance = 0.0
          for param_value in @class_values[class_value][param_name].keys
            @class_values[class_value][param_name][param_value].to_i.times do
              sum += param_value.to_f
            end
          end
          mean = sum / @class_values[class_value][param_name]['_TOTAL']
          @class_values[class_value][param_name].keys.each do |v|
            #next if v == "_TOTAL"
            r = v.to_f - mean
            @class_values[class_value][param_name][param_value].to_i.times do
              variance += (r * r) # add r^2 the number of times the value occurs
            end
          end
          @class_values[class_value][param_name] = {'_MEAN' => mean, '_VARIANCE' => variance}
        end
      end
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
        next if @param_types[param_name] == "continuous"
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
      if @param_types[param_name] == "discrete"
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
#puts "prob(#{i}): #{prob}"
        param_value = instance[i]
        if @param_types[param_name] == "continuous" 
            # TODO This needs to be scaled by something.  Perhaps the density_at for all class_values?
          prob *= NaiveBayes.density_at(@class_values[class_value][param_name]['_MEAN'].to_f, @class_values[class_value][param_name]['_VARIANCE'].to_f, param_value.to_f)
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

  def rate_accuracy(test_file_name)
    test_data = []
    File.open("#{Test_Data_Folder}/#{test_file_name}") do |f|
      @params = f.gets.chomp.split(',') # read param names from header
      @param_types = {}
      f.gets.chomp.split(',').each_with_index {|type, index| @param_types[@params[index]] = type} # read param types from header
      f.each_line do |line|
        test_data << line.chomp.split(/[,:]/)
      end
    end

    confusion_matrix = {:_TOTAL => test_data.size}
    test_data.each do |instance|
      actual_class_value = instance.delete_at(instance.size - 1)
      predicted_class_value = self.predict(instance)
      confusion_matrix[actual_class_value] ||= {:_TOTAL => 0}
      confusion_matrix[actual_class_value][:_TOTAL] += 1
      confusion_matrix[actual_class_value][predicted_class_value] ||= 0
      confusion_matrix[actual_class_value][predicted_class_value] += 1
    end
    confusion_matrix
  end

  def self.density_at (mean, variance, value)
    1/Math.sqrt(2*Math::PI*variance) * Math.exp(-((value-mean)*(value-mean))/(2 * variance))
  end

end

if __FILE__ == $0
  #NaiveBayes.new(training_file_name: "nb_training_data.txt").train_and_save
  NaiveBayes.new(config_file_name: "nb_config.csv") .rate_accuracy("nb_test_data.txt")
end
