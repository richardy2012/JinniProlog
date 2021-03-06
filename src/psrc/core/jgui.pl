/* 
  Reflection based GUI  
  - the default AWT GUI can be overriden by an external Swing based
    alternative Java implementation
  - looking the same from Prolog, although the external GUI is expected to
    offer extra functionality with time
*/

/* builtin to Java connection tools - based on Reflection based interface */

get_gui_class(CName):-get_global_prop(gui,swing),!,CName='jgui.Start'.
get_gui_class('prolog.core.GuiBuiltins').

call_gui_method(MethodAndArgs):-call_gui_method(MethodAndArgs,_).

call_gui_method(MethodAndArgs,Result):-
   get_gui_class(CName),
   call_java_class_method(
      CName,
      MethodAndArgs,
      Result
   ).

vdesktop:-call_java_class_method('agentgui.Main',startgui,_).

econsole:-launch_external(console).

iconsole:-launch_internal(console).

egui:-
 set_global_prop(gui,awt),
 set_global_prop(desktop,real).

igui:-
 set_global_prop(gui,swing),
 set_global_prop(desktop,virtual).
  
launch_external(Goal):-launch_in_gui(egui,Goal).

launch_internal(Goal):-launch_in_gui(igui,Goal).

launch_in_gui(Where,Goal):-
  get_global_prop(gui,GUI),
  get_global_prop(desktop,DT),
  Where,
  (call(Goal)->true ; println(failed_to_launch_in_gui=Goal)),
  set_global_prop(gui,GUI),
  set_global_prop(desktop,DT).
		 
/* builtins */

show(Container):-call_gui_method(show(Container)).
  
resize(Component,H,V):-call_gui_method(resize(Component,H,V)).

move(Component,H,V):-call_gui_method(move(Component,H,V)).

get_applet(A):-call_gui_method('get_applet',A).
get_applet_host(H):-call_gui_method('get_applet_host',H).

/* creates a new frame - top window */

new_frame(Frame):-new_frame('',Frame).

new_frame(Title,Frame):-get_global_prop('desktop','virtual'),!,new_inner_frame(Title,Frame).
new_frame(Title,Frame):-new_frame(Title,grid(1,1),Frame).

new_inner_frame(Title,Frame):-
  call_java_class_method('agentgui.Main',new_inner_frame(Title),Frame).

new_frame(Title,Layout,Frame):-
  Kind=1,
  new_frame(Title,Layout,Kind,Frame). 
  
new_frame(Title,Layout,Kind,Frame):-
  to_layout(Layout,L,X,Y),
  call_gui_method('new_frame'(Title,L,X,Y,Kind),Frame).

new_panel(Parent,Layout,Panel):-
  to_layout(Layout,L,X,Y),
  call_gui_method('new_panel'(Parent,L,X,Y),Panel).

new_label(Parent,Name,Label):-
   call_gui_method('new_label'(Parent,Name),Label).

new_button(Parent,Name,Action,Button):-
 new_button(Parent,Name,Action,'$null',Button).
 
new_button(Parent,Name,Action,Output,Button):-
   new_engine(yes,button_action(Action),Handle),
   handle2object(Handle,Machine),
   % engine_set_input(Machine,'$null'),
   output_area_to_pwriter(Output,PWriter),
   engine_set_output(Machine,PWriter),
   Goal='new_button'(Parent,Name,Machine),
   % button will die if action fails!
   call_gui_method(Goal,Button).

call_in_gui(Goal,OutputArea):-
   new_engine(Goal,Goal,Handle),
   handle2object(Handle,Machine),
   output_area_to_pwriter(OutputArea,PWriter),
   engine_set_output(Machine,PWriter),
   element_of(Handle,Answer),
   Answer=Goal.

output_area_to_pwriter('$null',PWriter):-!,PWriter='$null'. 
output_area_to_pwriter(Output,PWriter):-new_java_object('prolog.kernel.PWriter'(Output),PWriter).
 
button_action(Action):-repeat,if(topcall(Action),true,stop).
  
set_label(Label,String):-
   invoke_java_method(Label,setText(String),_).

new_file_dialog(Mode,Result):-
   call_gui_method('new_file_dialog'(Mode),Result).
   
new_text(Parent,Component):-
   new_text(Parent,'',5,20,Component).

new_text(Parent,String,Component):-
   new_text(Parent,String,2,24,Component).
   
new_text(Parent,String,Rows,Cols,Component):-
   call_gui_method('new_text'(Parent,String,Rows,Cols),Component).
   
set_text(Component,String):-
   invoke_java_method(Component,setText(String),_).  

% direct access to underlying TextSink - for visual displays only

set_text(String):-get_text_sink(Handle),set_text(Handle,String).

add_text(String):-get_text_sink(Handle),add_text(Handle,String).

get_text(String):-get_text_sink(Handle),get_text(Handle,String).

clear_text:-set_text('').

clear_text(Component):-set_text(Component,'').

% end of TextSink API

set_thread_wait(Ms):-call_java_class_method('jgui.Start',set_thread_wait(Ms),_).

add_text(Component,String):-
   invoke_java_method(Component,append_text(String),_).  

get_text(Component,String):-
   invoke_java_method(Component,getText,String).  

set_max_display(Max):-
   call_java_class_method('jgui.Displayer',set_max_display(Max),_).

/* Colors */

new_color(R,G,B,Color):-
   call_gui_method('new_color'(R,G,B),Color).

make_white(Color):-new_color(1,1,1,Color).
make_blue(Color):-new_color(0,0,1,Color).
make_light_blue(Color):-B is 10/10,Q is 8/10,new_color(Q,Q,B,Color).
make_gray(Color):-Q is 4/5,new_color(Q,Q,Q,Color).
make_green(Color):-new_color(0,1,0,Color).
make_red(Color):-new_color(1,0,0,Color).
make_black(Color):-new_color(0,0,0,Color).
   
set_fg(Component,Color):-      
  invoke_java_method(Component,setForeground(Color),_).  

set_bg(Component,Color):-      
  invoke_java_method(Component,setBackground(Color),_).  

set_color(Component,Color):-      
  invoke_java_method(Component,setColor(Color),_).  

/* Default Colors */

set_fg_color(R,G,B):-call_gui_method(set_fg_color(R,G,B)).
set_bg_color(R,G,B):-call_gui_method(set_bg_color(R,G,B)).

%get_fg_color(C):-call_gui_method(get_fg_color,C).
%get_bg_color(C):-call_gui_method(get_bg_color,C).

%to_default_fg(Component):-call_gui_method(to_default_fg(Component)).
%to_default_bg(Component):-call_gui_method(to_default_bg(Component)).

    
/* Default Fonts */

set_font_name(Name):-call_gui_method(set_font_name(Name)).
set_font_style(Style):-call_gui_method(set_font_style(Style)).
set_font_size(Size):-call_gui_method(set_font_size(Size)).
inc_font_size(Size):-call_gui_method(inc_font_size(Size)).

to_default_font(Component):-call_gui_method(to_default_font(Component)).

remove_all(Container):-
   invoke_java_method(Container,'removeAll',_).
   
destroy(Component):-
   call_gui_method('destroy'(Component)).

set_layout(Container,Layout):-
   to_layout(Layout,L,X,Y),
   call_gui_method('set_layout'(Container,L,X,Y)).

/* used on Panels and Frames with border layout */

set_direction(Container,String):-
   call_gui_method('set_direction'(Container,String),_).
   
to_layout(grid(X,Y),grid,X,Y):-!.
to_layout(L,L,0,0).

         
/* RLI eanbled GUI agents  */ 

rli_ide(WinName,PortName,InitialGoal):-
  Gui=new_ide,
  run_rli_gui(Gui,WinName,PortName,InitialGoal).

rli_console(WinName,PortName,InitialGoal):-
  Gui=new_console,
  run_rli_gui(Gui,WinName,PortName,InitialGoal).

% ////
run_rli_gui(Gui,WinName,PortName,InitialGoal):-
  new_frame(WinName,F),
  RLIGoal=rli_call(PortName,InitialGoal),
  to_string(RLIGoal,SGoal),
  call(Gui,F,SGoal,OutputArea),
  show(F),
  process_console_query(RLIGoal,OutputArea).

% ////  
swing_bg(Goal):-
  to_runnable(and(Goal,fail),Runnable),
  call_java_class_method(
    'jgui.Start',
     invokeLater(Runnable),
     _
  ).
  
/* Prolog IDE - contains simple editor and console */

ide:-getPrologName(P),namecat(P,' ','IDE',Name),ide(Name).

ide(Name):-ide(Name,'println(hello)').

ide(Name,Query):-
  new_frame(Name,F),
  new_ide(F,Query),
  show(F).

new_ide(Name):-ide(Name,'println(please(enter,a,query))').

new_ide(Container,Query):-
  new_ide(Container,Query,_Output).

new_ide(Container,Query,Output):-
  new_ide(Container,Query,Output,_EditArea).
  
new_ide(Container,Query,Output,EditArea):-
  new_panel(Container,grid(2,1),IDE),
  new_file_editor(IDE,EditArea),
  new_console(IDE,Query,Output).


/* simple Prolog Console - reads, evaluates, prints answers */
      
console:-new_console.
      
new_console:-
  new_console('println(hello)').

new_console(Query):-
  new_frame(F),
  new_console(F,Query),
  show(F).
   
new_console(Container,Query):-new_console(Container,Query,_Output).
   
new_console(Container,Query,Output):-new_console(Container,Query,10,20,Output).

new_console(Container,Query,Rows,Cols, Output):-
  new_panel(Container,border,P),
  set_direction(P,'Center'),
  new_text(P,'',Rows,Cols,Output), % output !!!
  % make_blue(Blue),set_fg(Output,Blue),
  % get_fg_color(FgColor),set_fg(Output,FgColor),
  set_direction(P,'North'),
  new_active_text(P,'West','?-',Query,1,Cols,'East','Run',
    console_action(Output),Output,_Button,Input), % top
  % to_boolean(false,False),invoke_java_method(Output,setEditable(False),_),
  invoke_java_method(Input,requestFocus,_).

/*
run_console_query(SQuery,OutputArea):-
  qsread_goal(SQuery,Goal,_NVs),
  process_console_query(Goal,Output).
*/

% ////  
process_console_query(rli_call(Port,Query),OutputArea):-
  !,
  output_area_to_pwriter(OutputArea,PWriter),
  % println(here=PWriter),
  rli_start_server(Port,PWriter),
  sleep_ms(50),
  rli_wait(Port),
  rli_call_nobind(Port,Query).
process_console_query(call(Query),OutputArea):-
  !,
  gui_topcall(OutputArea,Query).
process_console_query(_Query,_OutputArea).

console_action(Output,S):-
  name(NL,[10]),
  namecat('?- ',S,QS),
  add_text(Output,NL),
  add_text(Output,QS),
  add_text(Output,NL),
  console_goal_action(Output,NL,S).

console_goal_action(Output,NL,I):-
  call_ifdef(simple_console_action(I,O),fail),
  !,
  add_text(Output,O),
  add_text(Output,NL).
console_goal_action(Output,NL,S):- 
  if(
    qsread_goal(S,G,NVs),
    % should be in bg - otherwise gui_readln will block
    bg(
       do_console_action(G,NVs,Output,NL)
    )
    ,
    gui_exception(Output,NL,'syntax_error',S,true)
  ).
  
run_console_action(SG,Output):-
  qsread_goal(SG,G,_NVs),
  bg(quiet_console_action(G,Output)).

quiet_console_action(G,Output):-
 gui_topcall(Output,(G,fail;true)).
  
do_console_action(G,NVs,Output,NL):-
  (NVs=[]->
    (gui_topcall(Output,NL,G)->A=yes
    ; A=no
    ),
    add_text(Output,A),
    add_text(Output,NL)
  ; 
    foreach(gui_topcall(Output,NL,G),show_vars_in(Output,NVs,NL)),
    add_text(Output,no),
    add_text(Output,NL)
  ),  
  stop.

gui_topcall(Output,Goal):-
   name(NL,[10]),
   gui_topcall(Output,NL,Goal).
   
gui_topcall(Output,NL,Goal):-
  call_in_gui(catch(topcall(Goal),E,gui_exception(Output,NL,E,Goal,stop)),Output).

gui_exception(Output,NL,E,_Goal,Finally):-  
  swrite(E,SE),
  add_text(Output,'*** '),add_text(Output,SE),add_text(Output,NL),
  % swrite(Goal,SG),
  % add_text(Output,'in ==> '),add_text(Output,SG),add_text(Output,NL),
  Finally.
   
show_vars_in(Output,NVs,NL):-
  foreach(
    member(NV,NVs),
    show_one_var_in(Output,NV,NL)
  ),
  add_text(Output,(';')),
  add_text(Output,NL).
  
show_one_var_in(Output,N=V,NL):-
  add_text(Output,N),
  add_text(Output,'='),
  swrite(V,S),
  add_text(Output,S),
  % add_text(Output,(',')),
  add_text(Output,NL).
 
new_active_text(Parent,LDir,LName, InitString,Rows,Cols,Dir,AName,Action,Button, AText):-
   new_active_text(Parent,LDir,LName, InitString,Rows,Cols,Dir,AName,Action,'$null',Button, AText).
         
new_active_text(Parent,LDir,LName, InitString,Rows,Cols,
       Dir,
       AName,Action, % usually depending on output
       Output,
       Button, 
       AText):-
  new_panel(Parent,border,Panel),
  set_direction(Panel,LDir),
  new_label(Panel,LName,Label),
  set_direction(Panel,'Center'),
  new_text(Panel,InitString,Rows,Cols,Text), % input
  set_direction(Panel,Dir),
  % output can be a PWriter built around any TextSink
  new_button(Panel,AName,do_text_action(Text,Action),Output,Button),
  make_blue(Blue),
  set_fg(Text,Blue),
  make_black(Black),
  set_fg(Label,Black),
  set_fg(Button,Black),
  make_light_blue(LB),
  set_bg(Button,LB),
  set_bg(Label,LB),
  AText=Text.

do_text_action(Text,Action):-
  make_gray(Gray),
  get_text(Text,Content),
  set_bg(Text,Gray),
  set_text(Text,Content),
  call(Action,Content). 


/* Prolog Dialog Box - implemented using Hubs - to synchronize consumer and producer threads*/
dialog(Q,A):-dialog(Q,20,100,A).

dialog(Q,WhereX,WhereY,A):-
  dialog(Q,yes,no,WhereX,WhereY,200,50,A).

dialog(Q,Y,N,WhereX,WhereY,SizeX,SizeY,A):-
   new_frame('',grid(1,1),0,F),
   move(F,WhereX,WhereY),
   resize(F,SizeX,SizeY),
   dialog_in(F,Q,Y,N,A),
   destroy(F).

dialog_in(Parent,Q,A):-
   dialog_in(Parent,Q,yes,no,A).

dialog_in(Parent,Q,Y,N,A):-
   new_panel(Parent,border,F),
   set_direction(F,'Center'),
   new_label(F,Q,_),
   hub(H),
   set_direction(F,'East'),
   new_panel(F,grid(1,2),P),
   new_button(P,Y,hub_put(H,Y),_),
   new_button(P,N, hub_put(H,N),_),
   show(Parent),
   hub_collect(H,R),
   destroy(F),
   hub_stop(H), % should be last
   A=R.

/* reads a string from a new box - from which sread can be used
   to extract Prolog terms */
      
gui_readln(StringRead):-
   new_frame('',grid(1,1),0,F),resize(F,200,50),
   read_in(F,'>',StringRead),
   destroy(F).
  
read_in(Container,Prompt,StringRead):-
  read_in(Container,Prompt,'',0,0,StringRead).
  
read_in(Parent,Prompt,OldText,Rows,Cols,StringRead):-
  new_panel(Parent,border,Container),
  hub(H),
  new_active_text(Container,'West',Prompt,OldText,Rows,Cols,
    'East','Read',hub_put(H),_Button,_TextComponent),
  show(Parent),
  % println(hub=H),
  hub_collect(H,Result),
  destroy(Container),
  hub_stop(H),
  StringRead=Result.
   
/* Prolog Editor - squeeze to small default initial size size to
   fit on PocketPCs - resize at will ! */   

new_file_editor:-
  new_frame(F),
  new_file_editor(F,_),
  show(F).
        
new_file_editor(Container,Editor):-
  new_panel(Container,border,Panel),
  set_direction(Panel,'Center'),
  new_editor(Panel,Editor),
  set_direction(Panel,'North'),
  new_buttons(Panel, [
    'New'=>clear_action(Editor),
    'Load'=>load_action(Editor),
    '+'=>font_action(Editor,inc_font_size(2)),
    '-'=>font_action(Editor,inc_font_size(-2)),
    'Save'=>bg(save_action(Editor)),
    'Quit'=>halt
  ]).

font_action(Text,Action):-
   get_text(Text,Content),
   Action,
   set_text(Text,Content).
        
clear_action(Text):-
  make_white(White),
  set_bg(Text,White),
  set_text(Text,'').

load_action(Text):-
  new_file_dialog(0,File),
  load_to_text_area(File,Text).

load_to_text_area(File,Text):-
  file2string(File,S),
  make_white(White),
  set_bg(Text,White),
  set_text(Text,S).
  
save_action(Text):-
  new_file_dialog(1,File),
  File\=='$null',
  !,
  get_text(Text,Content),
  string2file(Content,File),
  make_gray(Gray),
  set_bg(Text,Gray).
save_action(_).
 
new_buttons(Parent,Xs):-
  length(Xs,N),
  new_panel(Parent,grid(1,N),Panel),
  new_buttons_in(Xs,Panel).

new_buttons_in([],_).
new_buttons_in([Name=>Action|Ps],Panel):-
  % println(here=Name),
  new_button(Panel,Name,Action,_Button),
  new_buttons_in(Ps,Panel).

% DEPRECATED


gui_write(GuiName,T):-
   GuiName==>Output,
   to_string(T,S),
   invoke_java_method(Output,append_text(S),_).

gui_print(GuiName,T):-gui_write(GuiName,T).

gui_println(GuiName,T):-gui_write(GuiName,T),gui_nl(GuiName).

gui_put_code(GuiName,Code):-
  GuiName==>Output,
  invoke_java_method(Output,appendCode(Code),_).
   
gui_nl(GuiName):-
   GuiName==>Output,
   invoke_java_method(Output,appendNL,_).


/* same - but in an applet context */
applet_ide:-applet_ide('println(hello)').

applet_ide(Query):-
  get_applet(F),
  new_label(F,'Coming out from the bottle!',_),
  ide('Prolog Applet',Query).

applet_console:-applet_console('println(hello)').

applet_console(Query):-
  get_applet(F),
  new_console(F,Query),
  show(F).
      

new_editor:-
  new_frame(F),
  new_editor(F,_),
  show(F).
    
edit(File0):-
  find_file(File0,File),
  new_frame(F),
  %new_file_editor(F,Editor),
  new_ide(F,'',_Output,Editor),
  load_to_text_area(File,Editor),
  show(F).


new_editor(Container):-new_editor(Container,_).

new_editor(Container,Editor):-
  new_editor(Container,'',Editor).

new_editor(Container,OldText,Editor):-
  new_editor(Container,OldText,0,0,Editor).

new_editor(Container,OldText,Rows,Cols,Editor):-
  new_active_text(Container,'North','Editor',OldText,Rows,Cols,
    'South',
    % 'Reconsult',reconsult_string,
    'Compile',scompile,
    _Button,T),
  Editor=T.  
  
