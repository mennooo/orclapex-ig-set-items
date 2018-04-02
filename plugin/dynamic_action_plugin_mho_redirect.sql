prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- ORACLE Application Express (APEX) export file
--
-- You should run the script connected to SQL*Plus as the Oracle user
-- APEX_050100 or as the owner (parsing schema) of the application.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_api.import_begin (
 p_version_yyyy_mm_dd=>'2016.08.24'
,p_release=>'5.1.4.00.08'
,p_default_workspace_id=>10390063953384733491
,p_default_application_id=>115922
,p_default_owner=>'CITIEST'
);
end;
/
prompt --application/shared_components/plugins/dynamic_action/mho_redirect
begin
wwv_flow_api.create_plugin(
 p_id=>wwv_flow_api.id(56584075706020401362)
,p_plugin_type=>'DYNAMIC ACTION'
,p_name=>'MHO.REDIRECT'
,p_display_name=>'Redirect'
,p_category=>'NAVIGATION'
,p_supported_ui_types=>'DESKTOP'
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'subtype t_url_type is varchar2(10);',
'',
'c_url_static                    constant t_url_type := ''static'';',
'c_url_plsql_expression          constant t_url_type := ''plsql'';',
'',
'------------------------------------------------------------------------------',
'-- function get_static_url',
'------------------------------------------------------------------------------  ',
'function get_static_url (',
'  p_static_url varchar2',
') return varchar2',
'is',
'',
'  l_url varchar2(32000);',
'',
'begin',
'',
'  l_url := apex_plugin_util.replace_substitutions(p_static_url);',
'  ',
'  l_url := apex_util.prepare_url(',
'    p_url           => l_url',
'  , p_checksum_type => ''SESSION''',
'  );',
'     ',
'  return l_url;',
'',
'end get_static_url;',
'',
'------------------------------------------------------------------------------',
'-- function get_url_via_plsql_expression',
'------------------------------------------------------------------------------',
'function get_url_via_plsql_expression (',
'  p_plsql_expression varchar2',
') return varchar2',
'is',
'begin',
'',
'  return apex_plugin_util.get_plsql_expression_result(p_plsql_expression);',
'',
'end get_url_via_plsql_expression;',
'',
'',
'------------------------------------------------------------------------------',
'-- function get_js_function',
'------------------------------------------------------------------------------',
'function get_js_function(',
'  p_static_url        varchar2',
', p_replace_on_exec   varchar2',
') return varchar2',
'',
'is',
'',
'  l_js  varchar2(4000);',
'',
'begin',
'',
'  if p_replace_on_exec = ''Y'' then',
'      ',
'    l_js :=',
'      q''[function() {',
'        mho.navigation.ajaxRedirect({',
'          da: this,',
'          itemsToSubmit: "#ITEMS_TO_SUBMIT#",',
'          ajaxIdentifier: "#AJAX_IDENTIFIER#",',
'          newWindow: #NEW_WINDOW#',
'        });',
'      }]'';',
'      ',
'  else',
'',
'    l_js := ''function() { mho.navigation.redirect(this, "'' || get_static_url(p_static_url) || ''", #NEW_WINDOW#); }'';',
'  ',
'  end if;',
'  ',
'  return l_js;',
'  ',
'end get_js_function;',
'',
'------------------------------------------------------------------------------',
'-- function get_js_function',
'------------------------------------------------------------------------------',
'function get_js_function (',
'  p_plsql_expression  varchar2',
') return varchar2',
'is',
'',
'  l_js  varchar2(4000);',
'  ',
'begin',
'',
'  l_js :=',
'    q''[function() {',
'      mho.navigation.ajaxRedirect({',
'        da: this,',
'        itemsToSubmit: "#ITEMS_TO_SUBMIT#",',
'        ajaxIdentifier: "#AJAX_IDENTIFIER#",',
'        newWindow: #NEW_WINDOW#',
'      });',
'    }]'';',
'  ',
'  return l_js;',
'',
'end get_js_function;',
'',
'------------------------------------------------------------------------------',
'-- function render',
'------------------------------------------------------------------------------',
'function render(p_dynamic_action in apex_plugin.t_dynamic_action',
'               ,p_plugin         in apex_plugin.t_plugin) return apex_plugin.t_dynamic_action_render_result',
'is',
'  l_js                  varchar2(4000); ',
'  l_items_to_submit     varchar2(4000);',
'  ',
'  l_url_type            apex_application_page_items.attribute_01%type := p_dynamic_action.attribute_01;',
'  l_static_url          apex_application_page_items.attribute_02%type := p_dynamic_action.attribute_02;',
'  l_plsql_expression    apex_application_page_items.attribute_03%type := p_dynamic_action.attribute_03;',
'  l_replace_on_exec     apex_application_page_items.attribute_04%type := p_dynamic_action.attribute_04;',
'  l_items_to_submit1    apex_application_page_items.attribute_05%type := p_dynamic_action.attribute_05;',
'  l_items_to_submit2    apex_application_page_items.attribute_06%type := p_dynamic_action.attribute_06;',
'  l_new_window          apex_application_page_items.attribute_07%type := p_dynamic_action.attribute_07;',
'  ',
'  l_result              apex_plugin.t_dynamic_action_render_result;',
'  ',
'begin',
'',
'  apex_plugin_util.debug_dynamic_action(p_plugin         => p_plugin',
'                                       ,p_dynamic_action => p_dynamic_action);',
'                                                                    ',
'  apex_javascript.add_library (',
'    p_name                    => ''apexNavigation#MIN#''',
'  , p_directory               => p_plugin.file_prefix',
'  , p_check_to_add_minified   => false',
'  ); ',
'',
'  l_js :=  ',
'    case l_url_type ',
'      when c_url_static then get_js_function(p_static_url => l_static_url, p_replace_on_exec => l_replace_on_exec)',
'      when c_url_plsql_expression then get_js_function(p_plsql_expression => l_plsql_expression)',
'    end;',
'',
'  l_items_to_submit :=  ',
'    case l_url_type ',
'      when c_url_static then l_items_to_submit1',
'      when c_url_plsql_expression then l_items_to_submit2',
'    end;',
'',
'  l_js := replace(l_js,''#ITEMS_TO_SUBMIT#'', apex_plugin_util.page_item_names_to_jquery(l_items_to_submit));',
'  l_js := replace(l_js,''#AJAX_IDENTIFIER#'', apex_plugin.get_ajax_identifier);',
'  l_js := replace(l_js,''#NEW_WINDOW#'', case when l_new_window = ''Y'' then ''true'' else ''false'' end);',
'',
'  l_result.javascript_function := l_js;',
'  ',
'  return l_result;',
'  ',
'end render;',
'',
'------------------------------------------------------------------------------',
'-- function ajax',
'------------------------------------------------------------------------------',
'function ajax(p_dynamic_action in apex_plugin.t_dynamic_action',
'             ,p_plugin         in apex_plugin.t_plugin) return apex_plugin.t_dynamic_action_ajax_result',
'is',
'',
'  l_url                 varchar2(32000);',
'  ',
'  l_url_type            apex_application_page_items.attribute_01%type := p_dynamic_action.attribute_01;',
'  l_static_url          apex_application_page_items.attribute_02%type := p_dynamic_action.attribute_02;',
'  l_plsql_expression    apex_application_page_items.attribute_03%type := p_dynamic_action.attribute_03;',
'  l_replace_on_exec     apex_application_page_items.attribute_04%type := p_dynamic_action.attribute_04;',
'  ',
'  ',
'  l_result              apex_plugin.t_dynamic_action_ajax_result;',
'',
'begin',
'',
'  l_url := ',
'    case l_url_type',
'      when c_url_static then get_static_url(l_static_url)',
'      when c_url_plsql_expression then get_url_via_plsql_expression(l_plsql_expression)',
'    end;',
'',
'  htp.prn(''{"url" : "'' || l_url || ''"}'');',
'',
'  return l_result;',
'    ',
'end ajax;'))
,p_api_version=>2
,p_render_function=>'render'
,p_ajax_function=>'ajax'
,p_standard_attributes=>'WAIT_FOR_RESULT'
,p_substitute_attributes=>true
,p_subscribe_plugin_settings=>true
,p_version_identifier=>'1.0'
,p_files_version=>9
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(56586483837894523532)
,p_plugin_id=>wwv_flow_api.id(56584075706020401362)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_prompt=>'URL Source'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'static'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(56586497440782531646)
,p_plugin_attribute_id=>wwv_flow_api.id(56586483837894523532)
,p_display_sequence=>10
,p_display_value=>'Static Value'
,p_return_value=>'static'
,p_help_text=>'Defines the URL in the plugin attributes'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(56586500081016534685)
,p_plugin_attribute_id=>wwv_flow_api.id(56586483837894523532)
,p_display_sequence=>20
,p_display_value=>'PL/SQL expression'
,p_return_value=>'plsql'
,p_help_text=>'Define the URL in a PL/SQL expression'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(56587688273322559014)
,p_plugin_id=>wwv_flow_api.id(56584075706020401362)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_prompt=>'Target'
,p_attribute_type=>'LINK'
,p_is_required=>true
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(56586483837894523532)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'static'
,p_help_text=>'The target URL to redirect to'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(56588187269756575835)
,p_plugin_id=>wwv_flow_api.id(56584075706020401362)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_prompt=>'PL/SQL Expression'
,p_attribute_type=>'PLSQL EXPRESSION'
,p_is_required=>true
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(56586483837894523532)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'plsql'
,p_examples=>'apex_page.get_url(p_page => 1);'
,p_help_text=>'A PL/SQL Expression that returns a URL.'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(56588860738970371959)
,p_plugin_id=>wwv_flow_api.id(56584075706020401362)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>40
,p_prompt=>'Update session state before redirect'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'N'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(56586483837894523532)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'static'
,p_help_text=>'Submit the items specified in the target before redirection. This way you get a URL including a checksum for items that have been changed by the user.'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(56589497839846603777)
,p_plugin_id=>wwv_flow_api.id(56584075706020401362)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>50
,p_prompt=>'Items to Submit'
,p_attribute_type=>'PAGE ITEMS'
,p_is_required=>false
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(56588860738970371959)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'Y'
,p_help_text=>'Enter page or application items to be set into session state before getting the URL for redirection. For multiple items, separate each item name with a comma. You can type in the name or pick from the list of available items. If you pick from the lis'
||'t and there is already text entered, then a comma is placed at the end of the existing text, followed by the item name returned from the list.'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(56604403389958943909)
,p_plugin_id=>wwv_flow_api.id(56584075706020401362)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>6
,p_display_sequence=>60
,p_prompt=>'Items to Submit'
,p_attribute_type=>'PAGE ITEMS'
,p_is_required=>false
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(56586483837894523532)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'plsql'
,p_help_text=>'Enter page or application items to be set into session state before getting the URL for redirection. For multiple items, separate each item name with a comma. You can type in the name or pick from the list of available items. If you pick from the lis'
||'t and there is already text entered, then a comma is placed at the end of the existing text, followed by the item name returned from the list.'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(56604487986979950967)
,p_plugin_id=>wwv_flow_api.id(56584075706020401362)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>7
,p_display_sequence=>70
,p_prompt=>'Open target in new window'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'N'
,p_is_translatable=>false
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '2F2A20676C6F62616C2061706578202A2F0D0A77696E646F772E6D686F203D2077696E646F772E6D686F207C7C207B7D0D0A3B2866756E6374696F6E20286E616D65737061636529207B0D0A20202F2F20437265617465206120636F7079206F66207468';
wwv_flow_api.g_varchar2_table(2) := '65206F726967696E616C206469616C6F672066756E6374696F6E2062656361757365207765206E65656420746F206368616E67652069740D0A202076617220674469616C6F674F726967203D20617065782E6E617669676174696F6E2E6469616C6F672E';
wwv_flow_api.g_varchar2_table(3) := '70726F746F747970655B27636F6E7374727563746F72275D0D0A0D0A20202F2F2043726561746520636F7079206F66206469616C6F67206D656D626572730D0A202076617220674469616C6F674D656D62657273203D204F626A6563742E6B6579732861';
wwv_flow_api.g_varchar2_table(4) := '7065782E6E617669676174696F6E2E6469616C6F67292E6D61702866756E6374696F6E20286D656D62657229207B0D0A2020202072657475726E207B0D0A2020202020206E616D653A206D656D6265722C0D0A2020202020206F626A6563743A20617065';
wwv_flow_api.g_varchar2_table(5) := '782E6E617669676174696F6E2E6469616C6F675B6D656D6265725D0D0A202020207D0D0A20207D290D0A0D0A20202F2F204368616E6765207468652074726967676572696E6720656C656D656E7420696E20746865206469616C6F672066756E6374696F';
wwv_flow_api.g_varchar2_table(6) := '6E0D0A202066756E6374696F6E205F7265706C6163654469616C6F67436F64652028646129207B0D0A0D0A202020202F2F205265706C616365206469616C6F672066756E6374696F6E0D0A20202020617065782E6E617669676174696F6E2E6469616C6F';
wwv_flow_api.g_varchar2_table(7) := '67203D2066756E6374696F6E202829207B0D0A2020202020202F2F2043726561746520616E206172726179206F6620616C6C20617267756D656E74730D0A2020202020207661722061726773203D2041727261792E70726F746F747970652E736C696365';
wwv_flow_api.g_varchar2_table(8) := '2E63616C6C28617267756D656E7473290D0A0D0A2020202020202F2F2043757272656E746C7920746869726420617267756D656E7420697320616C776179732074726967676572696E6720656C656D656E740D0A202020202020617267735B335D203D20';
wwv_flow_api.g_varchar2_table(9) := '64612E74726967676572696E67456C656D656E740D0A202020202020674469616C6F674F7269672E6170706C79286E756C6C2C2061726773290D0A202020207D0D0A202020202F2F2052652D617474616368206469616C6F67206D656D626572730D0A20';
wwv_flow_api.g_varchar2_table(10) := '202020674469616C6F674D656D626572732E666F72456163682866756E6374696F6E20286D656D62657229207B0D0A202020202020617065782E6E617669676174696F6E2E6469616C6F675B6D656D6265722E6E616D655D203D206D656D6265722E6F62';
wwv_flow_api.g_varchar2_table(11) := '6A6563740D0A202020207D290D0A20207D0D0A0D0A20202F2F20526573657420746865206469616C6F672066756E6374696F6E20746F20746865206F72696E616C206F6E650D0A202066756E6374696F6E205F72657365744469616C6F67436F64652028';
wwv_flow_api.g_varchar2_table(12) := '29207B0D0A2020202073657454696D656F75742866756E6374696F6E202829207B0D0A202020202020617065782E6E617669676174696F6E2E6469616C6F67203D20674469616C6F674F7269670D0A202020207D290D0A20207D0D0A0D0A202066756E63';
wwv_flow_api.g_varchar2_table(13) := '74696F6E207265646972656374202864612C2075726C2C206E657757696E646F7729207B0D0A20202020696620286E657757696E646F77203D3D3D207472756529207B0D0A2020202020202F2F204469616C6F67732077696C6C206E6576657220626520';
wwv_flow_api.g_varchar2_table(14) := '6F70656E656420696E2061206E65772077696E646F772072696768743F0D0A202020202020617065782E6E617669676174696F6E2E6F70656E496E4E657757696E646F772875726C290D0A202020207D20656C7365207B0D0A2020202020202F2F204F76';
wwv_flow_api.g_varchar2_table(15) := '65727269646520746865206469616C6F6720636F64650D0A2020202020205F7265706C6163654469616C6F67436F6465286461290D0A0D0A2020202020202F2F2045786563757465207265646972656374696F6E0D0A202020202020617065782E6E6176';
wwv_flow_api.g_varchar2_table(16) := '69676174696F6E2E72656469726563742875726C290D0A0D0A2020202020202F2F20416E64207265706C6163652077697468206F726967696E616C206469616C6F6720636F646520616761696E0D0A2020202020205F72657365744469616C6F67436F64';
wwv_flow_api.g_varchar2_table(17) := '6528290D0A202020207D0D0A20207D0D0A0D0A202066756E6374696F6E20616A6178526564697265637420286F7074696F6E7329207B0D0A20202020766172207265717565737444617461203D207B7D0D0A0D0A202020202F2F20416464207061676520';
wwv_flow_api.g_varchar2_table(18) := '6974656D7320746F207375626D697420746F20726571756573740D0A20202020696620286F7074696F6E732E6974656D73546F5375626D697429207B0D0A20202020202072657175657374446174612E706167654974656D73203D206F7074696F6E732E';
wwv_flow_api.g_varchar2_table(19) := '6974656D73546F5375626D69740D0A202020207D0D0A0D0A202020202F2F20537461727420414A41580D0A202020207661722070726F6D697365203D20617065782E7365727665722E706C7567696E286F7074696F6E732E616A61784964656E74696669';
wwv_flow_api.g_varchar2_table(20) := '65722C207265717565737444617461290D0A0D0A202020202F2F20526564697265637420616674657220414A41580D0A2020202070726F6D6973652E646F6E652866756E6374696F6E20286461746129207B0D0A2020202020207265646972656374286F';
wwv_flow_api.g_varchar2_table(21) := '7074696F6E732E64612C20646174612E75726C2C206F7074696F6E732E6E657757696E646F77290D0A202020202020617065782E64612E726573756D65286F7074696F6E732E64612E726573756D6543616C6C6261636B2C2066616C7365290D0A202020';
wwv_flow_api.g_varchar2_table(22) := '207D290D0A20207D0D0A0D0A20202F2F204164642066756E6374696F6E7320746F206E616D6573706163650D0A20206E616D6573706163652E6E617669676174696F6E203D207B0D0A2020202072656469726563743A2072656469726563742C0D0A2020';
wwv_flow_api.g_varchar2_table(23) := '2020616A617852656469726563743A20616A617852656469726563740D0A20207D0D0A7D292877696E646F772E6D686F290D0A';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(56593305881012405266)
,p_plugin_id=>wwv_flow_api.id(56584075706020401362)
,p_file_name=>'apexNavigation.js'
,p_mime_type=>'text/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '77696E646F772E6D686F3D77696E646F772E6D686F7C7C7B7D2C66756E6374696F6E286E297B66756E6374696F6E2061286E297B617065782E6E617669676174696F6E2E6469616C6F673D66756E6374696F6E28297B76617220613D41727261792E7072';
wwv_flow_api.g_varchar2_table(2) := '6F746F747970652E736C6963652E63616C6C28617267756D656E7473293B615B335D3D6E2E74726967676572696E67456C656D656E742C742E6170706C79286E756C6C2C61297D2C722E666F72456163682866756E6374696F6E286E297B617065782E6E';
wwv_flow_api.g_varchar2_table(3) := '617669676174696F6E2E6469616C6F675B6E2E6E616D655D3D6E2E6F626A6563747D297D66756E6374696F6E206928297B73657454696D656F75742866756E6374696F6E28297B617065782E6E617669676174696F6E2E6469616C6F673D747D297D6675';
wwv_flow_api.g_varchar2_table(4) := '6E6374696F6E2065286E2C652C6F297B6F3D3D3D21303F617065782E6E617669676174696F6E2E6F70656E496E4E657757696E646F772865293A2861286E292C617065782E6E617669676174696F6E2E72656469726563742865292C692829297D66756E';
wwv_flow_api.g_varchar2_table(5) := '6374696F6E206F286E297B76617220613D7B7D3B6E2E6974656D73546F5375626D6974262628612E706167654974656D733D6E2E6974656D73546F5375626D6974293B76617220693D617065782E7365727665722E706C7567696E286E2E616A61784964';
wwv_flow_api.g_varchar2_table(6) := '656E7469666965722C61293B692E646F6E652866756E6374696F6E2861297B65286E2E64612C612E75726C2C6E2E6E657757696E646F77292C617065782E64612E726573756D65286E2E64612E726573756D6543616C6C6261636B2C2131297D297D7661';
wwv_flow_api.g_varchar2_table(7) := '7220743D617065782E6E617669676174696F6E2E6469616C6F672E70726F746F747970652E636F6E7374727563746F722C723D4F626A6563742E6B65797328617065782E6E617669676174696F6E2E6469616C6F67292E6D61702866756E6374696F6E28';
wwv_flow_api.g_varchar2_table(8) := '6E297B72657475726E7B6E616D653A6E2C6F626A6563743A617065782E6E617669676174696F6E2E6469616C6F675B6E5D7D7D293B6E2E6E617669676174696F6E3D7B72656469726563743A652C616A617852656469726563743A6F7D7D2877696E646F';
wwv_flow_api.g_varchar2_table(9) := '772E6D686F293B';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(56593306178258405268)
,p_plugin_id=>wwv_flow_api.id(56584075706020401362)
,p_file_name=>'apexNavigation.min.js'
,p_mime_type=>'text/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false), p_is_component_import => true);
commit;
end;
/
set verify on feedback on define on
prompt  ...done
