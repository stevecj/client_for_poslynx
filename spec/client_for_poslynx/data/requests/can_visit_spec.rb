# coding: utf-8

require 'spec_helper'

module ClientForPoslynx

  describe Data::Requests::CanVisit do
    describe "the set of stub visitation methods" do
      let( :visitation_method_names ) {
        subject.instance_methods.select { |m| m =~ /^visit_[A-Z]/ }
      }

      it "only applies to existing request data classes" do
        class_names_from_methods = visitation_method_names.map{ |mn| "#{mn}".sub(/^visit_/, '') }
        class_names_from_methods.each do |class_name|
          expect( Data::Requests.const_get(class_name, false) ).to be_kind_of( Class )
        end
      end

      it "contains only methods invokable with visited object arguments" do
        obj = Object.new
        obj.extend subject
        visitation_method_names.each do |method_name|
          expect{ obj.public_send method_name, :some_visitee }.not_to raise_exception
        end
      end

      it "contains only methods that delegte to #visit_general" do
        obj = Object.new
        obj.extend subject
        class << obj
          def visitees ; @visitees ||= [] ; end
          def visit_general(visitee) ; visitees << visitee ; end
        end
        visitation_method_names.each do |method_name|
          obj.public_send method_name, :some_visitee
        end
        expect( obj.visitees ).to eq( [:some_visitee] * visitation_method_names.length )
      end
    end
  end

end
