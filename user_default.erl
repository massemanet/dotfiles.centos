%% -*- erlang-indent-level: 2 -*-
%%% Created :  7 Apr 2008 by Mats Cronqvist <masse@kreditor.se>

%% @doc
%% @end

-module('user_default').
-author('Mats Cronqvist').
-export([ineti/0,
         ports/0
         ,export_all/1
         ,tab/0
         ,long/1,flat/1,dump/1
         ,sig/1,sig/2
         ,e/2
         ,kill/1
         ,pi/1,pi/2
         ,os/1
         ,bt/1
         ,pid/1
         ,lm/0
         ,redbug/0,redbug/3]).

%% recompiles M with export_all without access to the source.
export_all(M) ->
  case code:which(M) of
    non_existing -> no_such_module;
    F ->
      {ok,{_,[{abstract_code,{_,AC}}]}} = beam_lib:chunks(F,[abstract_code]),
      {ok,_,B} = compile:forms(AC,[export_all]),
      code:soft_purge(M),
      code:load_binary(M,"",B)
  end.

lm() ->
    T = fun(L) -> [X || X <- L, element(1,X) =:= time] end,
    Tm = fun(M) -> T(M:module_info(compile)) end,
    Tf = fun(F) -> {ok,{_,[{_,I}]}}=beam_lib:chunks(F,[compile_info]),T(I) end,
    Load = fun(M) -> c:l(M),M end,

    [Load(M) || {M,F} <- code:all_loaded(), is_beamfile(F), Tm(M)<Tf(F)].

is_beamfile(F) ->
    ok == element(1,file:read_file_info(F)) andalso
        ".beam" == filename:extension(F).

tab() ->
  N=node(),
  io:setopts([{expand_fun,fun(B)->rpc:call(N,edlin_expand,expand,[B]) end}]).

sig(M) -> sig(M,'').
sig(M,F) when is_atom(M),is_atom(F) -> otp_doc:sig(M,F).

dump(Term)->
  {ok,FD}=file:open(filename:join([os:getenv("HOME"),"erlang.dump"]),[write]),
  try wr(FD,"~p.~n",Term)
  after file:close(FD)
  end.

flat(L) -> wr("~s~n",lists:flatten(L)).

long(X) -> wr(X).

e(N,T) when is_list(T) -> lists:nth(N,T);
e(N,T) when is_tuple(T) -> element(N,T).

kill(P) -> exit(pid(P),kill).

pi(P) -> process_info(pid(P)).
pi(P,Item) -> process_info(pid(P),Item).

os(Cmd) ->
  lists:foreach(fun(X)->wr("~s~n",X)end,string:tokens(os:cmd(Cmd),"\n")).

wr(E) -> wr("~p.~n",E).
wr(F,E) -> wr(user,F,E).
wr(FD,F,E) -> io:fwrite(FD,F,[E]).

redbug()->redbug:help().
redbug(A,B,C)->redbug:start(A,B,C).

bt(P) ->
  string:tokens(binary_to_list(e(2,process_info(pid(P),backtrace))),"\n").

pid(Pid) when is_list(Pid) -> list_to_pid(Pid);
pid(Pid) when is_pid(Pid) -> Pid;
pid(Atom) when is_atom(Atom) -> whereis(Atom);
pid({0,I2,I3}) when is_integer(I2) -> c:pid(0,I2,I3);
pid(I2) when is_integer(I2) -> pid({0,I2,0}).

ineti() ->
  io:fwrite("~15s:~-5s ~15s:~-5s ~7s ~9s ~s ~s~n",
            ["local","port","remote","port","type","status","sent","recvd"]),
  lists:foreach(fun ineti/1,ports()).

ineti(P) ->
  {_Fam,Type} = proplists:get_value(type,P),
  [Status|_]  = proplists:get_value(status,P),
  {LIP,LPort} = proplists:get_value(local,P),
  Sent        = proplists:get_value(sent,P),
  Recvd       = proplists:get_value(received,P),
  {RIP,RPort} =
    case proplists:get_value(remote,P) of
      enotconn -> {"*","*"};
      {Rip,Rp} -> {inet_parse:ntoa(Rip),integer_to_list(Rp)}
    end,
  io:fwrite("~15s:~-5w ~15s:~-5s ~7w ~9w ~w ~w~n",
            [inet_parse:ntoa(LIP),LPort,RIP,RPort,Type,Status,Sent,Recvd]).

ports() ->
  [port_info(P)++PI ||
    {P,PI}<-[{P,erlang:port_info(P)}||P<-erlang:ports()],
    lists:sublist(proplists:get_value(name,PI),4,100)=="_inet"].

port_info(P) ->
  {ok,Type} = prim_inet:gettype(P),
  {ok,Status} = prim_inet:getstatus(P),
  {ok,[{_,Sent}]} = prim_inet:getstat(P,[send_oct]),
  {ok,[{_,Recvd}]} = prim_inet:getstat(P,[recv_oct]),
  {ok,Local} = prim_inet:sockname(P),
  Remote = case prim_inet:peername(P) of
             {ok,R} -> R;
             {error,R} -> R
           end,
  [{type,Type},{status,Status},
   {sent,Sent},{received,Recvd},
   {local,Local},{remote,Remote}].
