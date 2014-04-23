require './prepare_data.rb'
require './tree.rb'
require './ann.rb'
require './naive_bayes.rb'
require './svm.rb'

class Classifiers

  All_Classifiers = [:id3, :ann, :nb, :svm]
  Training_Data_Folder = "training_data"
  Test_Data_Folder = "test_data"

  def initialize(params = {})
    @training_files = params[:training_files] || {}
    @test_files = params[:test_files] || {}
    @config_files = params[:config_files] || {}
    All_Classifiers.each do |classifier|
      @training_files[classifier] ||= "#{classifier.to_s}_training_data.txt"
      @test_files[classifier] ||= "#{classifier.to_s}_test_data.txt"
      @config_files[classifier] ||= "#{classifier.to_s}_config.txt"
    end

    if params[:force_prepare_data]
      PrepareData.new(params).prepare_data(:all)
    else
      data = PrepareData.new(params)
      All_Classifiers.each do |classifier|
        data.prepare_data(classifier) unless File.exist?(@training_files[classifier])
      end
    end

    set_classifiers(params[:classifiers] || :all)
    @classifier_instances = {}
  end

  # specify which of the classifiers should be used
  def set_classifiers(classifier_set)
    if classifier_set.is_a?(Symbol)
      if classifier_set == :all
        @classifiers = All_Classifiers
      elsif All_Classifiers.index(classifier_set)
        @classifiers = [classifier_set]
      else
        puts "Classifiers parameter '#{classifier.to_s}' is not a valid classifier"
      end
    elsif classifier_set.is_a?(Array)
      @classifiers = params[:classifiers]
    else
      puts "Classifier set params must be of type symbol or array"
    end
  end

  def train
    initialize_classifier_training = {
      :id3 => lambda {Tree.new(training_file_name: @training_files[:id3])},
      :ann => lambda {Ann.new(training_file_name: @training_files[:ann])},
      :nb => lambda {NaiveBayes.new(training_file_name: @training_files[:nb])},
      :svm => lambda {SVM.new(training_file_name: @training_files[:svm])}
    }

    @classifiers.each {|classifier| initialize_classifier_training[classifier].call.train_and_save}
  end

  def configure_from_file
    initialize_classifier = {
      :id3 => lambda {Tree.new(config_file_name: @config_files[:id3])},
      :ann => lambda {Ann.new(config_file_name: @config_files[:ann])},
      :nb => lambda {NaiveBayes.new(config_file_name: @config_files[:nb])},
      :svm => lambda {SVM.new(config_file_name: @config_files[:svm])}
    }

    @classifiers.each do |classifier|
      @classifier_instances[classifier] = initialize_classifier[classifier].call
    end
  end

  def rate_accuracy
    configure_from_file if @classifier_instances.empty?
    confusion_matrices = {}
    @classifiers.each {|classifier| confusion_matrices[classifier] = @classifier_instances[classifier].rate_accuracy(@test_files[classifier])}
    @classifiers.each do |classifier|
      confusion_matrix = confusion_matrices[classifier]
puts "confusion_matrix.inspect: #{confusion_matrix.inspect}"
      total_instances = confusion_matrix.delete(:_TOTAL)
      class_values = confusion_matrix.keys
puts "class_values.inspect: #{class_values.inspect}"
      
      puts "Results for #{classifier}"
      format = "%#{32}s\t%#{30}s\t%#{30}s\t%#{30}s\n"
      printf(format, "", "#{class_values[0].capitalize} (Actual)", "#{class_values[1].capitalize} (Actual)", "#{class_values[2].capitalize} (Actual)")
      class_values.each do |predicted_class|
        printf(format, "#{predicted_class.capitalize} (Predicted)",
        "#{confusion_matrix[class_values[0]][predicted_class]} (#{(confusion_matrix[class_values[0]][predicted_class].to_f / confusion_matrix[class_values[0]][:_TOTAL] * 100).round(2)}%)", 
        "#{confusion_matrix[class_values[1]][predicted_class]} (#{(confusion_matrix[class_values[1]][predicted_class].to_f / confusion_matrix[class_values[1]][:_TOTAL] * 100).round(2)}%)", 
        "#{confusion_matrix[class_values[2]][predicted_class]} (#{(confusion_matrix[class_values[2]][predicted_class].to_f / confusion_matrix[class_values[2]][:_TOTAL] * 100).round(2)}%)") 
      end
      correctly_classified_instances = class_values.inject(0) {|sum, class_value| sum += confusion_matrix[class_value][class_value]}
      puts "Overall accuracy: #{correctly_classified_instances} of #{total_instances} (#{(correctly_classified_instances.to_f / total_instances * 100).round(2)}%) instances classified correctly."
    end
  end
end

if __FILE__ == $0
  c = Classifiers.new(training_files: {nb: "nb_training_discretized.txt"}, test_files: {nb: "nb_test_discretized.txt"}, config_files: {nb: "nb_config.csv"}, classifiers: :nb, discretize_nb: true)
  c.configure_from_file
  c.rate_accuracy
end
