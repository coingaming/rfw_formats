defmodule RfwFormats.TextTest do
  use ExUnit.Case
  alias RfwFormats.Text
  alias RfwFormats.Model

  describe "Text parsing" do
    test "empty parseDataFile" do
      result = Text.parse_data_file("{}")
      assert result == %{}
    end

    test "empty parseLibraryFile" do
      result = Text.parse_library_file("")
      assert result.imports == []
      assert result.widgets == []
    end

    test "space parseDataFile" do
      result = Text.parse_data_file(" \n {} \n ")
      assert result == %{}
    end

    test "space parseLibraryFile" do
      result = Text.parse_library_file(" \n ")
      assert result.imports == []
      assert result.widgets == []
    end

    test "error handling in parseDataFile" do
      test_cases = [
        {"", "Expected symbol \"{\" but found <EOF> at line 1 column 0."},
        {"}", "Expected symbol \"{\" but found } at line 1 column 1."},
        {"1", "Expected symbol \"{\" but found 1 at line 1 column 1."},
        {"1.2", "Expected symbol \"{\" but found 1.2 at line 1 column 3."},
        {"a", "Expected symbol \"{\" but found a at line 1 column 1."},
        {"\"a\"", "Expected symbol \"{\" but found \"a\" at line 1 column 3."},
        {"&", "Unexpected character U+0026 (\"&\") at line 1 column 1."},
        {"\t", "Unexpected character U+0009 at line 1 column 1."},
        {"{ a: 0, a: 0 }", "Duplicate key \"a\" in map at line 1 column 10."},
        {"{ a: 0; }", "Expected symbol \"}\" but found ; at line 1 column 7."},
        {"{ a: [ 0 ; ] }", "Expected comma but found ; at line 1 column 10."},
        {"{ } x", "Expected end of file but found x at line 1 column 5."},
        {"{ a: a }", "Unexpected a at line 1 column 7."},
        {"{ ... }", "Expected symbol \"}\" but found … at line 1 column 5."},
        {"{ a: ... }", "Unexpected … at line 1 column 8."},
        {"{ a: -", "Unexpected end of file after minus sign at line 1 column 6."},
        {"{ a: -a",
         "Unexpected character U+0061 (\"a\") after minus sign (expected digit) at line 1 column 7."},
        {"{ a: 0", "Expected symbol \"}\" but found <EOF> at line 1 column 6."},
        {"{ a: 0e", "Unexpected end of file after exponent separator at line 1 column 7."},
        {"{ a: 0ee",
         "Unexpected character U+0065 (\"e\") after exponent separator at line 1 column 8."},
        {"{ a: 0e-",
         "Unexpected end of file after exponent separator and minus sign at line 1 column 8."},
        {"{ a: 0e-e", "Unexpected character U+0065 (\"e\") in exponent at line 1 column 9."},
        {"{ a: 0e-f", "Unexpected character U+0066 (\"f\") in exponent at line 1 column 9."},
        {"{ a: 0e-.", "Unexpected character U+002E (\".\") in exponent at line 1 column 9."},
        {"{ a: 0e- ", "Unexpected character U+0020 in exponent at line 1 column 9."},
        {"{ a: 0e-0", "Expected symbol \"}\" but found <EOF> at line 1 column 9."},
        {"{ a: 0e-0{", "Expected symbol \"}\" but found { at line 1 column 10."},
        {"{ a: 0e-0;", "Expected symbol \"}\" but found ; at line 1 column 10."},
        {"{ a: 0e-0e", "Unexpected character U+0065 (\"e\") in exponent at line 1 column 10."},
        {"{ a: 0 ", "Expected symbol \"}\" but found <EOF> at line 1 column 7."},
        {"{ a: 0.", "Unexpected end of file after decimal point at line 1 column 7."},
        {"{ a: 0.e",
         "Unexpected character U+0065 (\"e\") in fraction component at line 1 column 8."},
        {"{ a: 0. ", "Unexpected character U+0020 in fraction component at line 1 column 8."},
        {"{ a: 00", "Expected symbol \"}\" but found <EOF> at line 1 column 7."},
        {"{ a: 00e", "Unexpected end of file after exponent separator at line 1 column 8."},
        {"{ a: 00ee",
         "Unexpected character U+0065 (\"e\") after exponent separator at line 1 column 9."},
        {"{ a: 00e-",
         "Unexpected end of file after exponent separator and minus sign at line 1 column 9."},
        {"{ a: 00 ", "Expected symbol \"}\" but found <EOF> at line 1 column 8."},
        {"{ a: -0", "Expected symbol \"}\" but found <EOF> at line 1 column 7."},
        {"{ a: -0.", "Unexpected end of file after decimal point at line 1 column 8."},
        {"{ a: -0. ", "Unexpected character U+0020 in fraction component at line 1 column 9."},
        {"{ a: -0.0", "Expected symbol \"}\" but found <EOF> at line 1 column 9."},
        {"{ a: -0.0 ", "Expected symbol \"}\" but found <EOF> at line 1 column 10."},
        {"{ a: -0.0e", "Unexpected end of file after exponent separator at line 1 column 10."},
        {"{ a: -0.0ee",
         "Unexpected character U+0065 (\"e\") after exponent separator at line 1 column 11."},
        {"{ a: -0.0e-",
         "Unexpected end of file after exponent separator and minus sign at line 1 column 11."},
        {"{ a: -0.0f",
         "Unexpected character U+0066 (\"f\") in fraction component at line 1 column 10."},
        {"{ a: -00", "Expected symbol \"}\" but found <EOF> at line 1 column 8."},
        {"{ a: 0f", "Unexpected character U+0066 (\"f\") after zero at line 1 column 7."},
        {"{ a: -0f",
         "Unexpected character U+0066 (\"f\") after negative zero at line 1 column 8."},
        {"{ a: 00f", "Unexpected character U+0066 (\"f\") at line 1 column 8."},
        {"{ a: -00f", "Unexpected character U+0066 (\"f\") at line 1 column 9."},
        {"{ a: test.0", "Unexpected test at line 1 column 10."},
        {"{ a: test.0 ", "Unexpected test at line 1 column 10."},
        {"{ a: 0x", "Unexpected end of file after 0x prefix at line 1 column 7."},
        {"{ a: 0xg", "Unexpected character U+0067 (\"g\") after 0x prefix at line 1 column 8."},
        {"{ a: 0xx", "Unexpected character U+0078 (\"x\") after 0x prefix at line 1 column 8."},
        {"{ a: 0x}", "Unexpected character U+007D (\"}\") after 0x prefix at line 1 column 8."},
        {"{ a: 0x0", "Expected symbol \"}\" but found <EOF> at line 1 column 8."},
        {"{ a: 0xff", "Expected symbol \"}\" but found <EOF> at line 1 column 9."},
        {"{ a: 0xfg", "Unexpected character U+0067 (\"g\") in hex literal at line 1 column 9."},
        {"{ a: .\"hello\"", "Unexpected . at line 1 column 7."},
        {"{ a: \"hello\".\"hello\"", "Expected symbol \"}\" but found . at line 1 column 14."},
        {"{ a: \"hello\"", "Expected symbol \"}\" but found <EOF> at line 1 column 12."},
        {"{ a: \"\\n\"", "Unexpected end of line inside string at line 2 column 0."},
        {"{ a: \"hello\\n\"", "Unexpected end of line inside string at line 2 column 0."},
        {"{ a: \"\\", "Unexpected end of file inside string at line 1 column 7."},
        {"{ a: .\"hello\"", "Unexpected . at line 1 column 7."},
        {"{ \"a\": 'hello'.'hello'", "Expected symbol \"}\" but found . at line 1 column 16."},
        {"{ \"a\": 'hello'", "Expected symbol \"}\" but found <EOF> at line 1 column 14."},
        {"{ \"a\": 'hello'h",
         "Unexpected character U+0068 (\"h\") after end quote at line 1 column 15."},
        {"{ \"a\": '\\n'", "Unexpected end of line inside string at line 2 column 0."},
        {"{ \"a\": 'hello\\n'", "Unexpected end of line inside string at line 2 column 0."},
        {"{ \"a\": '\\", "Unexpected end of file inside string at line 1 column 9."},
        {"{ \"a\": '\\'", "Unexpected end of file inside string at line 1 column 10."},
        {"{ \"a\": '\\u", "Unexpected end of file inside Unicode escape at line 1 column 10."},
        {"{ \"a\": '\\u0", "Unexpected end of file inside Unicode escape at line 1 column 11."},
        {"{ \"a\": '\\u00", "Unexpected end of file inside Unicode escape at line 1 column 12."},
        {"{ \"a\": '\\u000", "Unexpected end of file inside Unicode escape at line 1 column 13."},
        {"{ \"a\": '\\u0000", "Unexpected end of file inside string at line 1 column 14."},
        {"{ \"a\": '\\u|",
         "Unexpected character U+007C (\"|\") in Unicode escape at line 1 column 11."},
        {"{ \"a\": '\\u0|",
         "Unexpected character U+007C (\"|\") in Unicode escape at line 1 column 12."},
        {"{ \"a\": '\\u00|",
         "Unexpected character U+007C (\"|\") in Unicode escape at line 1 column 13."},
        {"{ \"a\": '\\u000|",
         "Unexpected character U+007C (\"|\") in Unicode escape at line 1 column 14."},
        {"{ \"a\": '\\u0000|", "Unexpected end of file inside string at line 1 column 15."},
        {"{ \"a\": '\\U263A' }",
         "Unexpected character U+0055 (\"U\") after backslash in string at line 1 column 10."},
        {"{ \"a\": \"\\", "Unexpected end of file inside string at line 1 column 9."},
        {"{ \"a\": \"\\\"", "Unexpected end of file inside string at line 1 column 10."},
        {"{ \"a\": \"\\u", "Unexpected end of file inside Unicode escape at line 1 column 10."},
        {"{ \"a\": \"\\u0", "Unexpected end of file inside Unicode escape at line 1 column 11."},
        {"{ \"a\": \"\\u00", "Unexpected end of file inside Unicode escape at line 1 column 12."},
        {"{ \"a\": \"\\u000",
         "Unexpected end of file inside Unicode escape at line 1 column 13."},
        {"{ \"a\": \"\\u0000", "Unexpected end of file inside string at line 1 column 14."},
        {"{ \"a\": \"\\u|",
         "Unexpected character U+007C (\"|\") in Unicode escape at line 1 column 11."},
        {"{ \"a\": \"\\u0|",
         "Unexpected character U+007C (\"|\") in Unicode escape at line 1 column 12."},
        {"{ \"a\": \"\\u00|",
         "Unexpected character U+007C (\"|\") in Unicode escape at line 1 column 13."},
        {"{ \"a\": \"\\u000|",
         "Unexpected character U+007C (\"|\") in Unicode escape at line 1 column 14."},
        {"{ \"a\": \"\\u0000|", "Unexpected end of file inside string at line 1 column 15."},
        {"{ \"a\": \"\\U263A\" }",
         "Unexpected character U+0055 (\"U\") after backslash in string at line 1 column 10."},
        {"{ \"a\": ", "Unexpected <EOF> at line 1 column 7."},
        {"{ \"a\": /", "Unexpected end of file inside comment delimiter at line 1 column 8."},
        {"{ \"a\": /.",
         "Unexpected character U+002E (\".\") inside comment delimiter at line 1 column 9."},
        {"{ \"a\": //", "Unexpected <EOF> at line 1 column 9."},
        {"{ \"a\": /*", "Unexpected end of file in block comment at line 1 column 9."},
        {"{ \"a\": /*/", "Unexpected end of file in block comment at line 1 column 10."},
        {"{ \"a\": /**", "Unexpected end of file in block comment at line 1 column 10."},
        {"{ \"a\": /* *", "Unexpected end of file in block comment at line 1 column 11."}
      ]

      for {input, expected_message} <- test_cases do
        assert_raise Text.ParserException, expected_message, fn ->
          Text.parse_data_file(input)
        end
      end
    end

    test "valid values in parseDataFile" do
      assert Text.parse_data_file("{ }\n\n  \n\n") == %{}
      assert Text.parse_data_file("{ a: \"b\" }") == %{"a" => "b"}
      assert Text.parse_data_file("{ a: [ \"b\", 9 ] }") == %{"a" => ["b", 9]}
      assert Text.parse_data_file("{ a: { } }") == %{"a" => %{}}
      assert Text.parse_data_file("{ a: 123.456e7 }") == %{"a" => 123.456e7}
      assert Text.parse_data_file("{ a: true }") == %{"a" => true}
      assert Text.parse_data_file("{ a: false }") == %{"a" => false}
      assert Text.parse_data_file("{ \"a\": 0 }") == %{"a" => 0}
      assert Text.parse_data_file("{ \"a\": -0, b: \"x\" }") == %{"a" => 0, "b" => "x"}
      assert Text.parse_data_file("{ \"a\": null }") == %{}
      assert Text.parse_data_file("{ \"a\": -6 }") == %{"a" => -6}
      assert Text.parse_data_file("{ \"a\": -7 }") == %{"a" => -7}
      assert Text.parse_data_file("{ \"a\": -8 }") == %{"a" => -8}
      assert Text.parse_data_file("{ \"a\": -9 }") == %{"a" => -9}
      assert Text.parse_data_file("{ \"a\": 01 }") == %{"a" => 1}
      assert Text.parse_data_file("{ \"a\": 0e0 }") == %{"a" => 0.0}
      assert Text.parse_data_file("{ \"a\": 0e1 }") == %{"a" => 0.0}
      assert Text.parse_data_file("{ \"a\": 0e8 }") == %{"a" => 0.0}
      assert Text.parse_data_file("{ \"a\": 1e9 }") == %{"a" => 1.0e9}
      assert Text.parse_data_file("{ \"a\": -0e1 }") == %{"a" => 0.0}
      assert Text.parse_data_file("{ \"a\": 00e1 }") == %{"a" => 0.0}
      assert Text.parse_data_file("{ \"a\": -00e1 }") == %{"a" => 0.0}
      assert Text.parse_data_file("{ \"a\": 00.0e1 }") == %{"a" => 0.0}
      assert Text.parse_data_file("{ \"a\": -00.0e1 }") == %{"a" => 0.0}
      assert Text.parse_data_file("{ \"a\": -00.0e-1 }") == %{"a" => 0.0}
      assert Text.parse_data_file("{ \"a\": -1e-1 }") == %{"a" => -0.1}
      assert Text.parse_data_file("{ \"a\": -1e-2 }") == %{"a" => -0.01}
      assert Text.parse_data_file("{ \"a\": -1e-3 }") == %{"a" => -0.001}
      assert Text.parse_data_file("{ \"a\": -1e-4 }") == %{"a" => -0.0001}
      assert Text.parse_data_file("{ \"a\": -1e-5 }") == %{"a" => -0.00001}
      assert Text.parse_data_file("{ \"a\": -1e-6 }") == %{"a" => -0.000001}
      assert Text.parse_data_file("{ \"a\": -1e-7 }") == %{"a" => -0.0000001}
      assert Text.parse_data_file("{ \"a\": -1e-8 }") == %{"a" => -0.00000001}
      assert Text.parse_data_file("{ \"a\": -1e-9 }") == %{"a" => -0.000000001}
      assert Text.parse_data_file("{ \"a\": -1e-10 }") == %{"a" => -0.0000000001}
      assert Text.parse_data_file("{ \"a\": -1e-11 }") == %{"a" => -0.00000000001}
      assert Text.parse_data_file("{ \"a\": -1e-12 }") == %{"a" => -0.000000000001}
      assert Text.parse_data_file("{ \"a\": -1e-13 }") == %{"a" => -0.0000000000001}
      assert Text.parse_data_file("{ \"a\": -1e-14 }") == %{"a" => -0.00000000000001}
      assert Text.parse_data_file("{ \"a\": -1e-15 }") == %{"a" => -0.000000000000001}
      assert Text.parse_data_file("{ \"a\": -1e-16 }") == %{"a" => -0.0000000000000001}
      assert Text.parse_data_file("{ \"a\": -1e-17 }") == %{"a" => -0.00000000000000001}
      assert Text.parse_data_file("{ \"a\": -1e-18 }") == %{"a" => -1.0e-18}
      assert Text.parse_data_file("{ \"a\": -1e-19 }") == %{"a" => -1.0e-19}
      assert Text.parse_data_file("{ \"a\": 0x0 }") == %{"a" => 0}
      assert Text.parse_data_file("{ \"a\": 0x1 }") == %{"a" => 1}
      assert Text.parse_data_file("{ \"a\": 0x01 }") == %{"a" => 1}
      assert Text.parse_data_file("{ \"a\": 0xa }") == %{"a" => 10}
      assert Text.parse_data_file("{ \"a\": 0xb }") == %{"a" => 11}
      assert Text.parse_data_file("{ \"a\": 0xc }") == %{"a" => 12}
      assert Text.parse_data_file("{ \"a\": 0xd }") == %{"a" => 13}
      assert Text.parse_data_file("{ \"a\": 0xe }") == %{"a" => 14}
      assert Text.parse_data_file("{ \"a\": 0xfa }") == %{"a" => 250}
      assert Text.parse_data_file("{ \"a\": 0xfb }") == %{"a" => 251}
      assert Text.parse_data_file("{ \"a\": 0xfc }") == %{"a" => 252}
      assert Text.parse_data_file("{ \"a\": 0xfd }") == %{"a" => 253}
      assert Text.parse_data_file("{ \"a\": 0xfe }") == %{"a" => 254}

      assert Text.parse_data_file("{ \"a\": \"\\\"\\/\\'\\\b\\\f\\\n\\\r\\\t\\\\\" }") == %{
               "a" => "\"\/'\\b\\f\\n\\r\\t\\"
             }

      assert Text.parse_data_file("{ \"a\": '\\\"\\/\\\'\\b\\f\\n\\r\\t\\\\' }") == %{
               "a" => "\"\/'\\b\\f\\n\\r\\t\\"
             }

      assert Text.parse_data_file("{ \"a\": '\\u263A' }") == %{"a" => "☺"}
      assert Text.parse_data_file("{ \"a\": '\\u0000' }") == %{"a" => <<0>>}
      assert Text.parse_data_file("{ \"a\": '\\u1111' }") == %{"a" => "ᄑ"}
      assert Text.parse_data_file("{ \"a\": '\\u2222' }") == %{"a" => "∢"}
      assert Text.parse_data_file("{ \"a\": '\\u3333' }") == %{"a" => "㌳"}
      assert Text.parse_data_file("{ \"a\": '\\u4444' }") == %{"a" => "䑄"}
      assert Text.parse_data_file("{ \"a\": '\\u5555' }") == %{"a" => "啕"}
      assert Text.parse_data_file("{ \"a\": '\\u6666' }") == %{"a" => "晦"}
      assert Text.parse_data_file("{ \"a\": '\\u7777' }") == %{"a" => "睷"}
      assert Text.parse_data_file("{ \"a\": '\\u8888' }") == %{"a" => "袈"}
      assert Text.parse_data_file("{ \"a\": '\\u9999' }") == %{"a" => "香"}
      assert Text.parse_data_file("{ \"a\": '\\uaaaa' }") == %{"a" => "ꪪ"}
      assert Text.parse_data_file("{ \"a\": '\\ubbbb' }") == %{"a" => "뮻"}
      assert Text.parse_data_file("{ \"a\": '\\ucccc' }") == %{"a" => "쳌"}
      assert Text.parse_data_file("{ \"a\": '\\udddd' }") == %{"a" => <<0xDD, 0xDD::utf8>>}
      assert Text.parse_data_file("{ \"a\": '\\ueeee' }") == %{"a" => <<0xEE, 0xEE::utf8>>}
      assert Text.parse_data_file("{ \"a\": '\\uffff' }") == %{"a" => <<0xFF, 0xFF::utf8>>}
      assert Text.parse_data_file("{ \"a\": '\\uAAAA' }") == %{"a" => "ꪪ"}
      assert Text.parse_data_file("{ \"a\": '\\uBBBB' }") == %{"a" => "뮻"}
      assert Text.parse_data_file("{ \"a\": '\\uCCCC' }") == %{"a" => "쳌"}
      assert Text.parse_data_file("{ \"a\": '\\uDDDD' }") == %{"a" => <<0xDD, 0xDD::utf8>>}
      assert Text.parse_data_file("{ \"a\": '\\uEEEE' }") == %{"a" => <<0xEE, 0xEE::utf8>>}
      assert Text.parse_data_file("{ \"a\": '\\uFFFF' }") == %{"a" => <<0xFF, 0xFF::utf8>>}
      assert Text.parse_data_file("{ \"a\": /**/ \"1\" }") == %{"a" => "1"}
      assert Text.parse_data_file("{ \"a\": /* */ \"1\" }") == %{"a" => "1"}
      assert Text.parse_data_file("{ \"a\": /*\n*/ \"1\" }") == %{"a" => "1"}
    end

    test "error handling in parseLibraryFile" do
      test_cases = [
        {"2",
         "Expected keywords \"import\" or \"widget\", or end of file but found 2 at line 1 column 1."},
        {"impor",
         "Expected keywords \"import\" or \"widget\", or end of file but found impor at line 1 column 5."},
        {"import", "Expected string but found <EOF> at line 1 column 6."},
        {"import 2", "Expected string but found 2 at line 1 column 8."},
        {"import foo", "Expected symbol \";\" but found <EOF> at line 1 column 10."},
        {"import foo.", "Expected string but found <EOF> at line 1 column 11."},
        {"import foo,", "Expected symbol \";\" but found , at line 1 column 11."},
        {"import foo+",
         "Unexpected character U+002B (\"+\") inside identifier at line 1 column 11."},
        {"import foo.1", "Expected string but found 1 at line 1 column 12."},
        {"import foo.+", "Unexpected character U+002B (\"+\") after period at line 1 column 12."},
        {"import foo.\"", "Unexpected end of file inside string at line 1 column 12."},
        {"import foo. \"", "Unexpected end of file inside string at line 1 column 13."},
        {"import foo.'", "Unexpected end of file inside string at line 1 column 12."},
        {"import foo. '", "Unexpected end of file inside string at line 1 column 13."},
        {"widget a = b(c: [ ...for args in []: \"e\" ]);",
         "args is a reserved word at line 1 column 30."},
        {"widget a = switch 0 { 0: a(), 0: b() };",
         "Switch has duplicate cases for key 0 at line 1 column 32."},
        {"widget a = switch 0 { default: a(), default: b() };",
         "Switch has multiple default cases at line 1 column 44."},
        {"widget a = b(c: args)", "Expected symbol \".\" but found ) at line 1 column 21."},
        {"widget a = b(c: args.=)", "Unexpected = at line 1 column 22."},
        {"widget a = b(c: args.0", "Expected symbol \")\" but found <EOF> at line 1 column 22."},
        {"widget a = b(c: args.0 ", "Expected symbol \")\" but found <EOF> at line 1 column 23."},
        {"widget a = b(c: args.0)", "Expected symbol \";\" but found <EOF> at line 1 column 23."},
        {"widget a = b(c: args.0f",
         "Unexpected character U+0066 (\"f\") in integer at line 1 column 23."},
        {"widget a = b(c: [ ..",
         "Unexpected end of file inside \"...\" symbol at line 1 column 20."},
        {"widget a = b(c: [ .. ]);",
         "Unexpected character U+0020 inside \"...\" symbol at line 1 column 21."},
        {"widget a = b(c: [ ... ]);", "Expected identifier but found ] at line 1 column 23."},
        {"widget a = b(c: [ ...baa ]);", "Expected for but found baa at line 1 column 25."},
        {"widget a = 0;", "Expected identifier but found 0 at line 1 column 13."},
        {"widget a = a.", "Expected symbol \"(\" but found . at line 1 column 13."},
        {"widget a = a. ", "Expected symbol \"(\" but found . at line 1 column 14."},
        {"widget a = a.0", "Expected symbol \"(\" but found . at line 1 column 14."},
        {"widget a = a.0 ", "Expected symbol \"(\" but found . at line 1 column 14."}
      ]

      for {input, expected_message} <- test_cases do
        assert_raise Text.ParserException, expected_message, fn ->
          Text.parse_library_file(input)
        end
      end
    end

    test "parseLibraryFile: imports" do
      result = Text.parse_library_file("import foo.bar;")
      assert length(result.imports) == 1
      assert to_string(hd(result.imports)) == "import foo.bar;"
      assert result.widgets == []
    end

    test "parseLibraryFile: loops" do
      result = Text.parse_library_file("widget a = b(c: [ ...for d in []: \"e\" ]);")
      assert length(result.widgets) == 1
      assert to_string(hd(result.widgets)) == "widget a = b({c: [...for loop in []: e]});"
    end

    test "parseLibraryFile: switch" do
      assert to_string(Text.parse_library_file("widget a = switch 0 { 0: a() };")) ==
               "widget a = switch 0 {0: a({})};"

      assert to_string(Text.parse_library_file("widget a = switch 0 { default: a() };")) ==
               "widget a = switch 0 {null: a({})};"

      assert to_string(Text.parse_library_file("widget a = b(c: switch 1 { 2: 3 });")) ==
               "widget a = b({c: switch 1 {2: 3}});"
    end

    test "parseLibraryFile: references" do
      assert to_string(Text.parse_library_file("widget a = b(c:data.11234567890.\"e\");")) ==
               "widget a = b({c: data.11234567890.e});"

      assert to_string(Text.parse_library_file("widget a = b(c: [...for d in []: d]);")) ==
               "widget a = b({c: [...for loop in []: loop0.]});"

      assert to_string(Text.parse_library_file("widget a = b(c:args.foo.bar);")) ==
               "widget a = b({c: args.foo.bar});"

      assert to_string(Text.parse_library_file("widget a = b(c:data.foo.bar);")) ==
               "widget a = b({c: data.foo.bar});"

      assert to_string(Text.parse_library_file("widget a = b(c:state.foo.bar);")) ==
               "widget a = b({c: state.foo.bar});"

      assert to_string(Text.parse_library_file("widget a = b(c: [...for d in []: d.bar]);")) ==
               "widget a = b({c: [...for loop in []: loop0.bar]});"

      assert to_string(Text.parse_library_file("widget a = b(c:args.foo.\"bar\");")) ==
               "widget a = b({c: args.foo.bar});"

      assert to_string(Text.parse_library_file("widget a = b(c:data.foo.\"bar\");")) ==
               "widget a = b({c: data.foo.bar});"

      assert to_string(Text.parse_library_file("widget a = b(c:state.foo.\"bar\");")) ==
               "widget a = b({c: state.foo.bar});"

      assert to_string(Text.parse_library_file("widget a = b(c: [...for d in []: d.\"bar\"]);")) ==
               "widget a = b({c: [...for loop in []: loop0.bar]});"

      assert to_string(Text.parse_library_file("widget a = b(c:args.foo.9);")) ==
               "widget a = b({c: args.foo.9});"

      assert to_string(Text.parse_library_file("widget a = b(c:data.foo.9);")) ==
               "widget a = b({c: data.foo.9});"

      assert to_string(Text.parse_library_file("widget a = b(c:state.foo.9);")) ==
               "widget a = b({c: state.foo.9});"

      assert to_string(Text.parse_library_file("widget a = b(c: [...for d in []: d.9]);")) ==
               "widget a = b({c: [...for loop in []: loop0.9]});"

      assert to_string(Text.parse_library_file("widget a = b(c:args.foo.12);")) ==
               "widget a = b({c: args.foo.12});"

      assert to_string(Text.parse_library_file("widget a = b(c:data.foo.12);")) ==
               "widget a = b({c: data.foo.12});"

      assert to_string(Text.parse_library_file("widget a = b(c:state.foo.12);")) ==
               "widget a = b({c: state.foo.12});"

      assert to_string(Text.parse_library_file("widget a = b(c: [...for d in []: d.12]);")) ==
               "widget a = b({c: [...for loop in []: loop0.12]});"

      assert to_string(Text.parse_library_file("widget a = b(c:args.foo.98);")) ==
               "widget a = b({c: args.foo.98});"

      assert to_string(Text.parse_library_file("widget a = b(c:data.foo.98);")) ==
               "widget a = b({c: data.foo.98});"

      assert to_string(Text.parse_library_file("widget a = b(c:state.foo.98);")) ==
               "widget a = b({c: state.foo.98});"

      assert to_string(Text.parse_library_file("widget a = b(c: [...for d in []: d.98]);")) ==
               "widget a = b({c: [...for loop in []: loop0.98]});"

      assert to_string(Text.parse_library_file("widget a = b(c:args.foo.000);")) ==
               "widget a = b({c: args.foo.0});"

      assert to_string(Text.parse_library_file("widget a = b(c:data.foo.000);")) ==
               "widget a = b({c: data.foo.0});"

      assert to_string(Text.parse_library_file("widget a = b(c:state.foo.000);")) ==
               "widget a = b({c: state.foo.0});"

      assert to_string(Text.parse_library_file("widget a = b(c: [...for d in []: d.000]);")) ==
               "widget a = b({c: [...for loop in []: loop0.0]});"
    end

    test "parseLibraryFile: event handlers" do
      assert to_string(Text.parse_library_file("widget a = b(c: event \"d\" { });")) ==
               "widget a = b({c: event d {}});"

      assert to_string(Text.parse_library_file("widget a = b(c: set state.d = 0);")) ==
               "widget a = b({c: set state.d = 0});"
    end

    test "parseLibraryFile: stateful widgets" do
      assert to_string(Text.parse_library_file("widget a {} = c();")) == "widget a = c({});"
      assert to_string(Text.parse_library_file("widget a {b: 0} = c();")) == "widget a = c({});"

      result = Text.parse_library_file("widget a {b: 0} = c();")
      assert hd(result.widgets).initial_state == %{"b" => 0}
    end

    test "parseLibraryFile: widgetBuilders work" do
      result =
        Text.parse_library_file("""
          widget a = Builder(builder: (scope) => Container());
        """)

      assert to_string(result) ==
               "widget a = Builder({builder: (scope) => Container({})});"
    end

    test "parseLibraryFile: widgetBuilders work with arguments" do
      result =
        Text.parse_library_file("""
          widget a = Builder(builder: (scope) => Container(width: scope.width));
        """)

      assert to_string(result) ==
               "widget a = Builder({builder: (scope) => Container({width: scope.width})});"
    end

    test "parseLibraryFile: widgetBuilder arguments are lexical scoped" do
      result =
        Text.parse_library_file("""
          widget a = A(
            a: (s1) => B(
              b: (s2) => T(s1: s1.s1, s2: s2.s2),
            ),
          );
        """)

      assert to_string(result) ==
               "widget a = A({a: (s1) => B({b: (s2) => T({s1: s1.s1, s2: s2.s2})})});"
    end

    test "parseLibraryFile: widgetBuilder arguments can be shadowed" do
      result =
        Text.parse_library_file("""
          widget a = A(
            a: (s1) => B(
              b: (s1) => T(t: s1.foo),
            ),
          );
        """)

      assert to_string(result) ==
               "widget a = A({a: (s1) => B({b: (s1) => T({t: s1.foo})})});"
    end

    test "parseLibraryFile: widgetBuilders check the returned value" do
      assert_raise Text.ParserException,
                   "Expecting a switch or constructor call got 1 at line 1 column 27.",
                   fn ->
                     Text.parse_library_file("widget a = B(b: (foo) => 1);")
                   end
    end

    test "parseLibraryFile: widgetBuilders check reserved words" do
      assert_raise Text.ParserException, "args is a reserved word at line 1 column 34.", fn ->
        Text.parse_library_file(
          "widget a = Builder(builder: (args) => Container(width: args.width));"
        )
      end
    end

    test "parseLibraryFile: switch works with widgetBuilders" do
      result =
        Text.parse_library_file("""
          widget a = A(
            b: switch args.down {
              true: (foo) => B(),
              false: (bar) => C(),
            }
          );
        """)

      assert to_string(result) ==
               "widget a = A({b: switch args.down {true: (foo) => B({}), false: (bar) => C({})}});"
    end

    test "parseLibraryFile: widgetBuilders work with switch" do
      result =
        Text.parse_library_file("""
          widget a = A(
            b: (foo) => switch foo.letter {
              'a': A(),
              'b': B(),
            },
          );
        """)

      assert to_string(result) ==
               "widget a = A({b: (foo) => switch foo.letter {a: A({}), b: B({})}});"
    end

    test "parseLibraryFile: widgetBuilders work with lists" do
      result =
        Text.parse_library_file("""
          widget a = A(
            b: (s1) => B(c: [s1.c]),
          );
        """)

      assert to_string(result) == "widget a = A({b: (s1) => B({c: [s1.c]})});"
    end

    test "parseLibraryFile: widgetBuilders work with maps" do
      result =
        Text.parse_library_file("""
          widget a = A(
            b: (s1) => B(c: {d: s1.d}),
          );
        """)

      assert to_string(result) ==
               "widget a = A({b: (s1) => B({c: {d: s1.d}})});"
    end

    test "parseLibraryFile: widgetBuilders work with setters" do
      result =
        Text.parse_library_file("""
          widget a {foo: 0} = A(
            b: (s1) => B(onTap: set state.foo = s1.foo),
          );
        """)

      assert to_string(result) ==
               "widget a = A({b: (s1) => B({onTap: set state.foo = s1.foo})});"
    end

    test "parseLibraryFile: widgetBuilders work with events" do
      result =
        Text.parse_library_file("""
          widget a {foo: 0} = A(
            b: (s1) => B(onTap: event "foo" {result: s1.result})
          );
        """)

      assert to_string(result) ==
               "widget a = A({b: (s1) => B({onTap: event foo {result: s1.result}})});"
    end
  end
end
