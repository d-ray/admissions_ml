require './prepare_data.rb'
require './tree.rb'
require './ann.rb'

class Classifiers

  Classifiers = [:id3, :ann, :nb, :svm]
  Training_Data_Folder = "training_data"
  Test_Data_Folder = "test_data"

  def initialize(training_files = {}, test_files = {}, force_prepare_data = false, training_data = "admissions_data.csv")
    Classifiers.each do |classifier|
      training_files[classifier] ||= "#{Training_Data_Folder}/#{classifier.to_s}_training_data.txt"
      test_files[classifier] ||= "#{Test_Data_Folder}/#{classifier.to_s}_test_data.txt"
    end

    data = PrepareData.new(training_files, test_files, training_data)
    if force_prepare_data
      data.prepare_data(:all)
    else
      Classifiers.each do |classifier|
        data.prepare_data(classifier) unless File(training_files[classifier]).exist?
      end
    end
    @training_files = training_files
    @test_files = test_files
    @classifier_instances = []
  end

  def train
    @tree = Tree.new(training_file_name: @training_files[:id3])
    @tree.train_and_save

    @ann = Ann.new(training_file_name: @training_files[:ann])
    @ann.train_and_save

    @nb = NaiveBayes.new(training_file_name: @training_files[:nb])
    @nb.train_and_save

    @svm = SVM.new(training_file_name: @training_files[:svm])
    @svm.train_and_save
  end

  def configure_from_file(config_files = {})
    Classifiers.each {|classifier| config_files[classifier] ||= "#{classifier}_config.txt"}
    @classifier_instances << @tree = Tree.new(config_file_name: config_files[:id3])
    @classifier_instances << @ann = Ann.new(config_file_name: config_files[:ann])
    @classifier_instances << @nb = NaiveBayes.new(config_file_name: config_files[:nb])
    @classifier_instances << @svm = SVM.new(config_file_name: config_files[:svm])
  end

  def rate_accuracy
    configure_from_file if @classifier_instances.empty?
    @classifier_instances.each {|classifier| classifier.rate_accuracy}
  end
end

c = Classifiers.new.configure_from_file
c.rate_accuracy
