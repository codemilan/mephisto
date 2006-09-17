require File.dirname(__FILE__) + '/test_helper'

class FormHelperExtensionsTest < Test::Unit::TestCase
  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::PrototypeHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include SimplyHelpful::RecordIdentificationHelper
  
  def setup
    @record = Post.new
    @controller = Class.new do
      attr_reader :url_for_options
      def url_for(options, *parameters_for_method_reference)
        @url_for_options = options
        @url_for_options || "http://www.example.com"
      end
    end
    @controller = @controller.new
  end
  
  def test_form_for_with_record_identification_with_new_record
    _erbout = ''
    form_for(@record, {:html => { :id => 'create-post' }}) {}
    
    expected = "<form action='#{posts_url}' class='new_post' id='create-post' method='post'></form>"
    assert_dom_equal expected, _erbout
  end

  def test_form_for_with_record_identification_without_html_options
    _erbout = ''
    form_for(@record) {}
    
    expected = "<form action='#{posts_url}' class='new_post' method='post' id='new_post'></form>"
    assert_dom_equal expected, _erbout
  end

  def test_form_for_with_record_identification_with_existing_record
    @record.save
    _erbout = ''
    form_for(@record) {}
    
    expected = "<form action='#{post_url(@record)}' class='edit_post' id='edit_post_1' method='post'><input type='hidden' name='_method' value='put' /></form>"
    assert_dom_equal expected, _erbout
  end

  def test_remote_form_for_with_record_identification_with_new_record
    _erbout = ''
    remote_form_for(@record, {:html => { :id => 'create-post' }}) {}
    
    expected = %(<form action='#{posts_url}' onsubmit="new Ajax.Request('#{posts_url}', {asynchronous:true, evalScripts:true, parameters:Form.serialize(this)}); return false;" class='new_post' id='create-post' method='post'></form>)
    assert_dom_equal expected, _erbout
  end

  def test_remote_form_for_with_record_identification_without_html_options
    _erbout = ''
    remote_form_for(@record) {}
    
    expected = %(<form action='#{posts_url}' onsubmit="new Ajax.Request('#{posts_url}', {asynchronous:true, evalScripts:true, parameters:Form.serialize(this)}); return false;" class='new_post' method='post' id='new_post'></form>)
    assert_dom_equal expected, _erbout
  end

  def test_remote_form_for_with_record_identification_with_existing_record
    @record.save
    _erbout = ''
    remote_form_for(@record) {}
    
    expected = %(<form action='#{post_url(@record)}' onsubmit="new Ajax.Request('#{post_url(@record)}', {asynchronous:true, evalScripts:true, parameters:Form.serialize(this)}); return false;" class='edit_post' id='edit_post_1' method='post'><input type='hidden' name='_method' value='put' /></form>)
    assert_dom_equal expected, _erbout
  end
end