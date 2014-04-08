require 'libsvm'

class SVM

  # the path to the training data folder
  Training_Data_Folder = "training_data"
  # the path to the test data folder
  Test_Data_Folder = "test_data"
  # the path to the config file folder
  Config_Folder = "config"


  def initialize(params = {})
    if params[:training_file_name]
      training_data = []
      File.open("#{Training_Data_Folder}/#{params[:training_file_name]}") do |f| 
#        f.each_line do |line|
#          instance = line.chomp.split(/[,:]/)
#          class_value = instance.delete_at(instance.size - 1)
#          training_data << [Libsvm::Node.features(instance.map(&:to_f)), class_value.to_f]
#        end 
        2.times {f.gets} # get rid of header
        
        f.each_line do |line|
          case line.chomp
          when "" #ignore blank lines
          when /^[01] [01] [01]$/
            class_value = line.chomp.split(' ').map! {|n| n.to_f}
            test_data << [@attributes, class_value]
            training_data << [Libsvm::Node.features(attributes), class_value.to_f]
          else
            @attributes = line.chomp.split(' ').map! {|n| n.to_f}
          end
        end
      end 

      @problem = Libsvm::Problem.new
      @problem.set_examples(training_data.map(&:last), training_data.map(&:first))

      @parameter = Libsvm::SvmParameter.new
      @parameter.cache_size = 1 # in megabytes
      @parameter.eps = 0.001
      @parameter.c = 10
    elsif params[:config_file_name]
      @svm = Libsvm::Model.load("#{Config_Folder}/#{params[:config_file_name]}")
    else
      puts "Unrecognized parameters"
    end
  end

  def train
    @svm = Libsvm::Model.train(@problem, @parameter)
  end

  def train_and_save(config_file = "svm_config.txt")
    train
    @svm.save("#{Config_Folder}/#{config_file}")
  end

  def rate_accuracy(test_file_name)
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
puts "@svm.predict(Libsvm::Node.features(instance)): #{@svm.predict(Libsvm::Node.features(instance)).inspect}"
      classification_counts[class_value][:correct] += 1 if (@svm.predict(Libsvm::Node.features(instance)) == class_value)
    end
    
    total_correct = 0
    classification_counts.values.each {|h| total_correct += h[:correct]}
    puts "Total: #{total_correct} out of #{test_data.size} (#{(total_correct.to_f / test_data.size) * 100}%) correctly classified"
    puts "By class value:"
    classification_counts.each {|kv_pair| puts "Value #{kv_pair.first}: #{kv_pair.last[:correct]} out of #{kv_pair.last[:total]} (#{(kv_pair.last[:correct].to_f / kv_pair.last[:total]) * 100}%) correctly classified"}
  end
end

#SVM.new({training_file_name: "svm_training_data.txt"}).train_and_save
SVM.new({config_file_name: "svm_config.txt"}).rate_accuracy("svm_test_data.txt")
