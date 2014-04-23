require 'libsvm'

class SVM

  # the path to the training data folder
  Training_Data_Folder = "training_data"
  # the path to the test data folder
  Test_Data_Folder = "test_data"
  # the path to the config file folder
  Config_Folder = "config"

  SVM_Class_Values = {"no_admit" => "-1", "admit_no_matriculate" => "0", "admit_matriculate" => "1"}

  def initialize(params = {})
    if params[:training_file_name]
      training_data = []
      File.open("#{Training_Data_Folder}/#{params[:training_file_name]}") do |f| 
        f.each_line do |line|
          instance = line.chomp.split(/[ :]/)
          class_value = instance.delete_at(instance.size - 1)
          training_data << [Libsvm::Node.features(instance.map(&:to_f)), class_value.to_f]
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

    confusion_matrix = {:_TOTAL => test_data.size}
    test_data.each do |instance|
      actual_class_value = SVM_Class_Values.key(instance.delete_at(instance.size - 1))
      predicted_class_value = SVM_Class_Values.key(@svm.predict(Libsvm::Node.features(instance)))
      confusion_matrix[actual_class_value] ||= {:_TOTAL => 0}
      confusion_matrix[actual_class_value][:_TOTAL] += 1
      confusion_matrix[actual_class_value][predicted_class_value] ||= 0
      confusion_matrix[actual_class_value][predicted_class_value] += 1
    end
    confusion_matrix
  end
end

if __FILE__ == $0
  SVM.new({training_file_name: "svm_training_binary_decision.txt"}).train_and_save
  #SVM.new({config_file_name: "svm_config.txt"}).rate_accuracy("svm_test_data.txt")
end
