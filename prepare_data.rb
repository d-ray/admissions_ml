class PrepareData

  # the types of classifiers to prepare data for
  Classifiers = [:id3, :ann, :nb, :svm]
  # the path to the training data folder
  Training_Data_Folder = "training_data"
  # the path to the test data folder
  Test_Data_Folder = "test_data"

  # ID3 specific values
  Default_Value = "no_admit"

  # ANN specific values
  ANN_Class_Values = {"no_admit" => "1 0 0", "admit_no_matriculate" => "0 1 0", "admit_matriculate" => "0 0 1"}

  # Naive Bayes specific values
  GPA_Discretization = [1.0,1.5,2.0,2.5,3.0,3.5,4.0]
  SAT_Discretization = [700,750,800,850,900,950,1000,1050,1100,1150,1200,1250,1300,1350,1450,1500,1550]
  Academic_Index_Discretization = [5000,5500,6000,6500,7000,7500,8000,8500,9000,9500]
  Family_Income_Discretization = [20000,50000,100000,200000,500000]
  Contribution_Discretization = [2000,5000,10000,20000,50000]
  Gift_Discretization = [5000,10000,15000,20000,25000,30000]

  # Support Vector Machine specific values
  SVM_Class_Values = {"no_admit" => "0", "admit_no_matriculate" => "1", "admit_matriculate" => "2"}

  Attributes = [
    [:id, {type: :unused}],
    [:gender, {type: :discrete, discrete_options: 2}],
    [:ethnicity, {type: :discrete, discrete_options: 10}],
    [:state, {type: :discrete, discrete_options: 60}],
    [:postal_code, {type: :discrete, continuous_denominator: 100000}], # 12500 for zip code distances
    [:country, {type: :discrete, discrete_options: 196}],
    [:major1, {type: :discrete, discrete_options: 113}],
    [:major2, {type: :discrete, discrete_options: 113}],
    [:major3, {type: :discrete, discrete_options: 113}],
    [:hs_CEEB_code, {type: :discrete, discrete_options: 0, continuous_denominator: 0}],
    [:hs_GPA, {type: :continuous, discretization: GPA_Discretization, continuous_denominator: 5}],
    [:grad_year, {type: :unused, discrete_options: 0, continuous_denominator: 0}],
    [:ACT_score, {type: :discrete, continuous_denominator: 36}],
    [:SAT_score, {type: :continuous, discretization: SAT_Discretization, continuous_denominator: 1600}],
    [:application_date, {type: :unused, discrete_options: 0, continuous_denominator: 0}],
    [:initial_visit_code, {type: :discrete, discrete_options: 6}],
    [:initial_visit_date, {type: :unused, discrete_options: 0, continuous_denominator: 0}],
    [:initial_inquiry_code, {type: :discrete, discrete_options: 131}],
    [:initial_inquiry_date, {type: :unused, discrete_options: 0, continuous_denominator: 0}],
    [:admit_date, {type: :unused, class_value: true}],
    [:enrollment_date, {type: :unused, class_value: true}],
    [:deposit_date, {type: :unused}],
    [:first_source_app, {type: :discrete, discrete_options: 2}],
    [:entry_term, {type: :unused, discrete_options: 0, continuous_denominator: 0}],
    [:opportunity_type, {type: :discrete, discrete_options: 4}],
    [:application_status, {type: :unused}],
    [:scholarships, {type: :discrete, discrete_options: 9}],
    [:scholarships_bumped, {type: :discrete, discrete_options: 4, continuous_denominator: 0}],
    [:academic_index, {type: :continuous, discretization: Academic_Index_Discretization, continuous_denominator: 10000}],
    [:academic_year, {type: :unused, discrete_options: 0, continuous_denominator: 0}],
    [:family_income, {type: :continuous, discretization: Family_Income_Discretization, discrete_options: 1, continuous_denominator: 100000000}],
    [:family_contribution, {type: :continuous, discretization: Contribution_Discretization, discrete_options: 1, continuous_denominator: 100000000}],
    [:total_gift_aid, {type: :continuous, discretization: Gift_Discretization, discrete_options: 1, continuous_denominator: 100000}],
    [:admit_status, {type: :unused}]
  ]

  # initialized with a csv file containing data instances for training/testing
  def initialize(partition_by_year = false, training_files = {}, test_files = {}, data_file = "admissions_data.csv")
    Classifiers.each do |classifier|
      training_files[classifier] ||= "#{classifier.to_s}_training_data.txt"
      test_files[classifier] ||= "#{classifier.to_s}_test_data.txt"
    end
    @training_files = training_files
    @test_files = test_files

    class_value_attribute_indices = {}
    academic_year_index = -1
    Attributes.each_with_index  do |attribute, index|
      if attribute.last[:class_value]
        class_value_attribute_indices[attribute.first] = index 
      elsif attribute.first == :academic_year
        academic_year_index = index
      end
    end 

    @discrete_options_to_numbers = []
    Attributes.size.times {@discrete_options_to_numbers << {}} # contains one hash per attribute

    # training and test sets are arrays of pairs consisting of an instance's attribute values and its class value
    @training_data = []
    @test_data = []

    File.open(data_file) do |f|
      f.gets # ignore header
      f.each_line do |line|
        line.gsub!(/".*,.*"/) {|attribute| "\\#{attribute.gsub(',','')}"} #remove commas contained in matched quotes
        instance_array = line.chomp.split(',')

        class_value_attributes = {}
        class_value_attribute_indices.each {|kv_pair| class_value_attributes[kv_pair.first] = instance_array[kv_pair.last]}
        class_value = determine_class_value(class_value_attributes)
        (Attributes.size - instance_array.size).times {instance_array << ""} #ensure the appropriate number of attributes in case trailing empty strings are dropped
        #Reject_Indices.sort! {|m,n| n <=> m} # sort indices in descending order
        #Reject_Indices.each {|n| instance_array.delete_at(n)}
        if partition_by_year
          #if instance_array[academic_year_index].slice(0,4) == Time.now.year #TODO
          if instance_array[academic_year_index].slice(0,4) == "2013"
            @test_data << [instance_array, class_value]
          else
            @training_data << [instance_array, class_value]
          end
        else
          if rand(3) == 0
            @test_data << [instance_array, class_value]
          else
            @training_data << [instance_array, class_value]
          end
        end
      end
    end
  end

  # create data files specific to one of the classifiers for both training and testing
  def prepare_data(algorithm)
    case algorithm
    when :id3
      prepare_id3_data 
    when :ann
      prepare_ann_data
    when :nb
      prepare_nb_data
    when :svm
      prepare_svm_data
    when :all
      prepare_all_data
    end
  end

  private

  def prepare_all_data
    prepare_id3_data
    prepare_ann_data
    prepare_nb_data
    prepare_svm_data
  end

  def prepare_id3_data
    write_id3_file("#{Training_Data_Folder}/#{@training_files[:id3]}", @training_data)
    write_id3_file("#{Test_Data_Folder}/#{@test_files[:id3]}", @test_data)
  end

  def write_id3_file(file, data)
    # construct the header - list of each attribute with its type (discrete or continuous)
    header = ""
    Attributes.each_with_index do |attribute, index|
      next if attribute.last[:type] == :unused
      header << "#{attribute.first.to_s}:#{attribute.last[:type].to_s},"
    end

    # write header and each data instance (attribute values : class value) to the file
    File.open(file, "w") do |f|
      f.puts("#{header.chomp(',')}")
      f.puts(Default_Value)
      data.each do |instance|
        instance_data = ""
        instance.first.each_with_index do |attribute_value, index|
           instance_data << "#{attribute_value}," unless Attributes[index].last[:type] == :unused
        end
        f.puts("#{instance_data.chomp(',')}:#{instance.last}") # add class value at the end
      end
    end
  end

  def prepare_ann_data
    write_ann_file("#{Training_Data_Folder}/#{@training_files[:ann]}", @training_data)
    write_ann_file("#{Test_Data_Folder}/#{@test_files[:ann]}", @test_data)
  end

  def write_ann_file(file, data)
    # determine the number of total input nodes
    num_inputs = 0
    Attributes.each do |attribute|
      if attribute.last[:discrete_options]
        num_inputs += attribute.last[:discrete_options]
      elsif attribute.last[:continuous_denominator]
        num_inputs += 1
      end
    end

    # header consists of number of inputs, number of data instances, and number of outputs
    header = "#{num_inputs} #{data.size} #{ANN_Class_Values.size}"

    # write header and each data instance to the file
    File.open(file, "w") do |f|
      f.puts("#{header}\n\n")
      data.each do |instance|
        instance_data = ""
        instance.first.each_with_index do |attribute_value, index|
          if Attributes[index].last[:discrete_options]
            # discrete attribute
            instance_data << "#{convert_discrete_attribute_to_ann_input(attribute_value, index)} "
          elsif Attributes[index].last[:continuous_denominator]
            # continuous attribute
            instance_data << "#{attribute_value.to_f / Attributes[index].last[:continuous_denominator]} "
          end
        end
        f.puts("#{instance_data.chomp(' ')}\n\n") # inputs for given attribute values
        f.puts("#{ANN_Class_Values[instance.last]}\n\n") # class value
      end
    end
  end

  def prepare_nb_data
    write_nb_file("#{Training_Data_Folder}/#{@training_files[:nb]}", @training_data)
    write_nb_file("#{Test_Data_Folder}/#{@test_files[:nb]}", @test_data)
  end

  def write_nb_file(file, data)
    header = ""
    Attributes.each do |attribute| 
      header << "#{attribute.first}," unless attribute.last[:type] == :unused
    end

    File.open(file, "w") do |f|
      f.puts(header.chomp(','))
      data.each do |instance|
        instance_data = ""
        instance.first.each_with_index do |attribute_value, index|
          if Attributes[index].last[:type] == :unused
            next
          elsif Attributes[index].last[:discretization]
            instance_data << "#{discretize(attribute_value, Attributes[index].last[:discretization])},"
          else
            instance_data << "#{attribute_value},"
          end
        end
        f.puts("#{instance_data.chomp(',')}:#{instance.last}") # add class value at the end
      end
    end
  end

  def prepare_svm_data
    write_svm_file("#{Training_Data_Folder}/#{@training_files[:svm]}", @training_data)
    write_svm_file("#{Test_Data_Folder}/#{@test_files[:svm]}", @test_data)
  end

  def write_svm_file(file, data)
    File.open(file, "w") do |f|
      #f.puts(header.chomp(','))
      data.each do |instance|
        instance_data = ""
        instance.first.each_with_index do |attribute_value, index|
          if Attributes[index].last[:type] == :unused
            next
          else
            instance_data << "#{convert_attribute_to_numeric_option(attribute_value,index)},"
          end
        end
        f.puts("#{instance_data.chomp(',')}:#{SVM_Class_Values[instance.last]}") # add class value at the end
      end
    end
  end

  def determine_class_value(attributes)
    if attributes[:admit_date].empty?
      "no_admit"
    elsif attributes[:enrollment_date].empty?
      "admit_no_matriculate"
    else
      "admit_matriculate"
    end
  end

  def convert_attribute_to_numeric_option(attribute, index)
    attribute_option_hash = @discrete_options_to_numbers[index]
    attribute_option_hash[attribute] = attribute_option_hash.size if attribute_option_hash[attribute].nil?
    attribute_option_hash[attribute]
  end

  def convert_discrete_attribute_to_ann_input(attribute, index)
return "" if Attributes[index].last[:discrete_options] == 0
    numeric_option = convert_attribute_to_numeric_option(attribute, index)
    
    attribute_array = Array.new(Attributes[index].last[:discrete_options], 0)
    attribute_array[numeric_option] = 1
    attribute_array.to_s.gsub(/[\[\],]/, '')
  end

  def discretize(attribute, discretization)
    return "" if attribute.empty?

    discretization.each_with_index do |boundary,index|
      if index == 0
        return "< #{boundary}" if attribute.to_f < boundary
      else
        return "#{discretization[index - 1]}..#{boundary.to_s}" if attribute.to_f < boundary
      end
    end
    return ">= #{discretization.last}"
  end
end

PrepareData.new(true, {ann: "ann_train_by_year.txt", id3: "id3_train_by_year.txt", nb: "nb_train_by_year.txt", svm: "svm_train_by_year.txt"}, {ann: "ann_test_by_year.txt", id3: "id3_test_by_year.txt", nb: "nb_test_by_year.txt", svm: "svm_test_by_year.txt"}).prepare_data(:all)
