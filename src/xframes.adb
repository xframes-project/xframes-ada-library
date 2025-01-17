with System;                use System;
with Interfaces.C;          use Interfaces.C;
with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Float_Text_IO;     use Ada.Float_Text_IO;
with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Strings.Hash;
with GNATCOLL.JSON;         use GNATCOLL.JSON;
with GNATCOLL.Strings;      use GNATCOLL.Strings;

procedure Main is
   package String_Hashed_Maps is new
     Ada.Containers.Indefinite_Hashed_Maps
       (Key_Type        => String,
        Element_Type    => String,
        Hash            => Ada.Strings.Hash,
        Equivalent_Keys => "=");

   use String_Hashed_Maps;

   type ImGuiCol is
     (Text,
      TextDisabled,
      WindowBg,
      ChildBg,
      PopupBg,
      Border,
      BorderShadow,
      FrameBg,
      FrameBgHovered,
      FrameBgActive,
      TitleBg,
      TitleBgActive,
      TitleBgCollapsed,
      MenuBarBg,
      ScrollbarBg,
      ScrollbarGrab,
      ScrollbarGrabHovered,
      ScrollbarGrabActive,
      CheckMark,
      SliderGrab,
      SliderGrabActive,
      Button,
      ButtonHovered,
      ButtonActive,
      Header,
      HeaderHovered,
      HeaderActive,
      Separator,
      SeparatorHovered,
      SeparatorActive,
      ResizeGrip,
      ResizeGripHovered,
      ResizeGripActive,
      Tab,
      TabHovered,
      TabActive,
      TabUnfocused,
      TabUnfocusedActive,
      PlotLines,
      PlotLinesHovered,
      PlotHistogram,
      PlotHistogramHovered,
      TableHeaderBg,
      TableBorderStrong,
      TableBorderLight,
      TableRowBg,
      TableRowBgAlt,
      TextSelectedBg,
      DragDropTarget,
      NavHighlight,
      NavWindowingHighlight,
      NavWindowingDimBg,
      ModalWindowDimBg,
      COUNT);

   type Float_Array is array (Positive range <>) of aliased Float;
   type Font_Sizes_Array is array (1 .. 8) of Integer;

   function Create_HEXA_As_JSON_Array
     (Color : String; Opacity : Float) return JSON_Array
   is
      Temp : JSON_Array;
   begin
      Temp := Empty_Array;
      Append (Temp, Create (String'(Color)));
      Append (Temp, Create (Float'(Opacity)));
      return Temp;
   end Create_HEXA_As_JSON_Array;

   function Create_Node (Id : Integer; Is_Root : Boolean) return JSON_Value is
      Temp : JSON_Value;
   begin
      Temp := Create_Object;
      Temp.Set_Field (Field_Name => "id", Field => Create (Integer'(Id)));
      Temp.Set_Field
        (Field_Name => "root", Field => Create (Boolean'(Is_Root)));
      Temp.Set_Field (Field_Name => "type", Field => Create (String'("node")));

      return Temp;
   end Create_Node;

   function Create_Unformatted_Text
     (Id : Integer; Text : String) return JSON_Value
   is
      Temp : JSON_Value;
   begin
      Temp := Create_Object;
      Temp.Set_Field (Field_Name => "id", Field => Create (Integer'(Id)));
      Temp.Set_Field (Field_Name => "text", Field => Create (String'(Text)));
      Temp.Set_Field
        (Field_Name => "type", Field => Create (String'("unformatted-text")));

      return Temp;
   end Create_Unformatted_Text;

   procedure Set_Theme_Color_Json
     (Theme        : in out JSON_Value;
      Theme_Colors : JSON_Value;
      ImGui_Color  : ImGuiCol;
      Color_Name   : String;
      Opacity      : Float) is
   begin

      declare
         Key         : String := Integer'Image (ImGuiCol'Pos (ImGui_Color));
         Color_Value : String := String'(Theme_Colors.Get (Color_Name));
      begin
         Theme.Set_Field
           (Field_Name => Key,
            Field      => Create_HEXA_As_JSON_Array (Color_Value, Opacity));
      end;
   end Set_Theme_Color_Json;

   procedure Set_Element (Element_Json : in out Interfaces.C.char_array);
   pragma Import (C, Set_Element, "setElement");

   procedure Set_Children
     (Id : Integer; Children_Ids : in out Interfaces.C.char_array);
   pragma Import (C, Set_Children, "setChildren");

   procedure Init;
   pragma Convention (C, Init);

   procedure Init is
      Root_Node          : JSON_Value;
      Unformatted_Text   : JSON_Value;
      Children_Ids_Array : JSON_Array;
      Children_Ids       : JSON_Value;

      Root_Node_C_Char_Array       : Interfaces.C.char_array (1 .. 1024);
      Root_Node_C_Char_Array_Count : Size_T;

      Unformatted_Text_C_Char_Array       :
        Interfaces.C.char_array (1 .. 1024);
      Unformatted_Text_C_Char_Array_Count : Size_T;

      Children_Ids_C_Char_Array       : Interfaces.C.char_array (1 .. 1024);
      Children_Ids_C_Char_Array_Count : Size_T;
   begin
      Root_Node := Create_Node (0, True);
      Unformatted_Text := Create_Unformatted_Text (1, "Hello, world");

      To_C
        (Item       => Root_Node.Write,
         Target     => Root_Node_C_Char_Array,
         Count      => Root_Node_C_Char_Array_Count,
         Append_Nul => True);

      To_C
        (Item       => Unformatted_Text.Write,
         Target     => Unformatted_Text_C_Char_Array,
         Count      => Unformatted_Text_C_Char_Array_Count,
         Append_Nul => True);

      Children_Ids_Array := Empty_Array;

      Append (Children_Ids_Array, Create (Integer'(1)));

      Children_Ids := Create (Children_Ids_Array);

      To_C
        (Item       => Children_Ids.Write,
         Target     => Children_Ids_C_Char_Array,
         Count      => Children_Ids_C_Char_Array_Count,
         Append_Nul => True);

      Set_Element (Root_Node_C_Char_Array);
      Set_Element (Unformatted_Text_C_Char_Array);
      Set_Children (0, Children_Ids_C_Char_Array);
   end Init;

   procedure OnTextChanged
     (Id : Integer; Text : in out Interfaces.C.char_array);
   pragma Convention (C, OnTextChanged);

   procedure OnTextChanged
     (Id : Integer; Text : in out Interfaces.C.char_array) is
   begin
      Put_Line
        ("OnTextChanged called with ID: "
         & Integer'Image (Id)
         & " and Text: ");
   end OnTextChanged;

   procedure OnComboChanged (Id : Integer; Selected_Option_Id : Integer);
   pragma Convention (C, OnComboChanged);

   procedure OnComboChanged (Id : Integer; Selected_Option_Id : Integer) is
   begin
      Put_Line
        ("OnComboChanged called with ID: " & Integer'Image (Id) & " and: ");
   end OnComboChanged;

   procedure OnNumericValueChanged (Id : Integer; Value : Float);
   pragma Convention (C, OnNumericValueChanged);

   procedure OnNumericValueChanged (Id : Integer; Value : Float) is
   begin
      Put_Line
        ("Callback called with ID: "
         & Integer'Image (Id)
         & " and Value: "
         & Float'Image (Value));
   end OnNumericValueChanged;

   procedure OnBooleanValueChanged (Id : Integer; Value : Boolean);
   pragma Convention (C, OnBooleanValueChanged);

   procedure OnBooleanValueChanged (Id : Integer; Value : Boolean) is
   begin
      Put_Line
        ("OnBooleanValueChanged called with ID: "
         & Integer'Image (Id)
         & " and Value: "
         & Boolean'Image (Value));
   end OnBooleanValueChanged;

   procedure MultipleNumericValuesChanged
     (Id : Integer; Values : access Float_Array; NumValues : Integer);
   pragma Convention (C, MultipleNumericValuesChanged);

   procedure MultipleNumericValuesChanged
     (Id : Integer; Values : access Float_Array; NumValues : Integer) is
   begin
      Ada.Text_IO.Put_Line
        ("MultipleNumericValuesChanged numeric values changed callback invoked.");
      Ada.Text_IO.Put_Line ("ID: " & Integer'Image (Id));
      Ada.Text_IO.Put_Line ("Number of Values: " & Integer'Image (NumValues));

      for I in 1 .. NumValues loop
         Ada.Text_IO.Put_Line
           ("Value " & Integer'Image (I) & ": " & Float'Image (Values (I)));
      end loop;
   end MultipleNumericValuesChanged;

   procedure OnClick (Id : Integer; Value : Boolean);
   pragma Convention (C, OnClick);

   procedure OnClick (Id : Integer; Value : Boolean) is
   begin
      Put_Line ("OnClick called with ID: " & Integer'Image (Id));
   end OnClick;

   Init_Address                         : System.Address := Init'Address;
   OnTextChanged_Address                : System.Address :=
     OnTextChanged'Address;
   OnComboChanged_Address               : System.Address :=
     OnComboChanged'Address;
   OnNumericValueChanged_Address        : System.Address :=
     OnNumericValueChanged'Address;
   OnBooleanValueChanged_Address        : System.Address :=
     OnBooleanValueChanged'Address;
   MultipleNumericValuesChanged_Address : System.Address :=
     MultipleNumericValuesChanged'Address;
   OnClick_Address                      : System.Address := OnClick'Address;

   procedure Extern_Init
     (Assets_Base_Path               : in out Interfaces.C.char_array;
      Raw_Font_Definitions           : in out Interfaces.C.char_array;
      Raw_Style_Override_Definitions : in out Interfaces.C.char_array;
      OnInit                         : System.Address;
      OnTextChanged                  : System.Address;
      OnComboChanged                 : System.Address;
      OnNumericValueChanged          : System.Address;
      OnBooleanValueChanged          : System.Address;
      MultipleNumericValuesChanged   : System.Address;
      OnClick                        : System.Address);
   pragma Import (C, Extern_Init, "init");

   Assets_Base_Path               : constant String := "./assets";
   Raw_Font_Definitions           : String := "";
   Raw_Style_Override_Definitions : String := "";

   Assets_Base_Path_C               : Interfaces.C.char_array :=
     To_C (Assets_Base_Path);
   Raw_Font_Definitions_C           : Interfaces.C.char_array (1 .. 1024 * 5);
   Raw_Style_Override_Definitions_C : Interfaces.C.char_array (1 .. 1024 * 10);

   Raw_Font_Definitions_String_Length           : Size_T;
   Raw_Style_Override_Definitions_String_Length : Size_T;

   Input_String : String (1 .. 100);
   Last_Index   : Natural;

   Font_Sizes                     : Font_Sizes_Array :=
     (16, 18, 20, 24, 28, 32, 36, 48);
   Font_Definitions               : JSON_Array := Empty_Array;
   Tmp_Font_Definition            : JSON_Value;
   Font_Definitions_As_JSON_Value : JSON_Value;

   --  Theme_Colors : String_Hashed_Maps.Map;

   Theme_Colors : JSON_Value := Create_Object;

   Theme : JSON_Value := Create_Object;
begin
   -- Font definitions

   for I in Font_Sizes'Range loop
      Tmp_Font_Definition := Create_Object;
      Tmp_Font_Definition.Set_Field
        (Field_Name => "name", Field => "roboto-regular");
      Tmp_Font_Definition.Set_Field
        (Field_Name => "size", Field => Create (Integer'(Font_Sizes (I))));

      Append (Font_Definitions, Tmp_Font_Definition);
   end loop;

   Font_Definitions_As_JSON_Value := Create_Object;
   Font_Definitions_As_JSON_Value.Set_Field
     (Field_Name => "defs", Field => Create (Font_Definitions));

   To_C
     (Item       => Font_Definitions_As_JSON_Value.Write,
      Target     => Raw_Font_Definitions_C,
      Count      => Raw_Font_Definitions_String_Length,
      Append_Nul => True);

   Put_Line (Write (Font_Definitions_As_JSON_Value));

   -- Theme definition

   Theme_Colors.Set_Field (Field_Name => "darkestGrey", Field => "#141f2c");
   Theme_Colors.Set_Field (Field_Name => "darkerGrey", Field => "#2a2e39");
   Theme_Colors.Set_Field (Field_Name => "darkGrey", Field => "#363b4a");
   Theme_Colors.Set_Field (Field_Name => "lightGrey", Field => "#5a5a5a");
   Theme_Colors.Set_Field (Field_Name => "lighterGrey", Field => "#7A818C");
   Theme_Colors.Set_Field
     (Field_Name => "evenLighterGrey", Field => "#8491a3");
   Theme_Colors.Set_Field (Field_Name => "black", Field => "#0A0B0D");
   Theme_Colors.Set_Field (Field_Name => "green", Field => "#75f986");
   Theme_Colors.Set_Field (Field_Name => "red", Field => "#ff0062");
   Theme_Colors.Set_Field (Field_Name => "white", Field => "#fff");

   Set_Theme_Color_Json (Theme, Theme_Colors, Text, "white", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, TextDisabled, "lighterGrey", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, WindowBg, "black", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, ChildBg, "black", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, PopupBg, "white", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, Border, "lightGrey", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, BorderShadow, "darkestGrey", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, FrameBg, "black", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, FrameBgHovered, "darkerGrey", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, FrameBgActive, "lightGrey", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, TitleBg, "lightGrey", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, TitleBgActive, "darkerGrey", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, TitleBgCollapsed, "lightGrey", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, MenuBarBg, "lightGrey", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, ScrollbarBg, "darkerGrey", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, ScrollbarGrab, "darkerGrey", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, ScrollbarGrabHovered, "lightGrey", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, ScrollbarGrabActive, "darkestGrey", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, CheckMark, "darkestGrey", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, SliderGrab, "darkerGrey", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, SliderGrabActive, "lightGrey", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, Button, "black", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, ButtonHovered, "darkerGrey", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, ButtonActive, "black", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, Header, "black", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, HeaderHovered, "black", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, HeaderActive, "lightGrey", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, Separator, "darkestGrey", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, SeparatorHovered, "lightGrey", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, SeparatorActive, "lightGrey", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, ResizeGrip, "black", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, ResizeGripHovered, "lightGrey", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, ResizeGripActive, "darkerGrey", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, Tab, "black", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, TabHovered, "darkerGrey", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, TabActive, "lightGrey", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, TabUnfocused, "black", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, TabUnfocusedActive, "lightGrey", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, PlotLines, "darkerGrey", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, PlotLinesHovered, "lightGrey", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, PlotHistogram, "darkerGrey", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, PlotHistogramHovered, "lightGrey", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, TableHeaderBg, "black", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, TableBorderStrong, "lightGrey", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, TableBorderLight, "darkerGrey", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, TableRowBg, "darkGrey", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, TableRowBgAlt, "darkerGrey", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, TextSelectedBg, "darkerGrey", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, DragDropTarget, "darkerGrey", 1.0);
   Set_Theme_Color_Json (Theme, Theme_Colors, NavHighlight, "darkerGrey", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, NavWindowingHighlight, "darkerGrey", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, NavWindowingDimBg, "darkerGrey", 1.0);
   Set_Theme_Color_Json
     (Theme, Theme_Colors, ModalWindowDimBg, "darkerGrey", 1.0);

   Put_Line ("Theme JSON Object: " & Theme.Write);

   To_C
     (Item       => Theme.Write,
      Target     => Raw_Style_Override_Definitions_C,
      Count      => Raw_Style_Override_Definitions_String_Length,
      Append_Nul => True);

   Extern_Init
     (Assets_Base_Path_C,
      Raw_Font_Definitions_C,
      Raw_Style_Override_Definitions_C,
      Init_Address,
      OnTextChanged_Address,
      OnComboChanged_Address,
      OnNumericValueChanged_Address,
      OnBooleanValueChanged_Address,
      MultipleNumericValuesChanged_Address,
      OnClick_Address);

   Get_Line (Input_String, Last_Index);
end Main;
