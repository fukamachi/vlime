function! TestGetNthVarArg()
    call assert_equal('default', vlime#GetNthVarArg([], 0, 'default'))
    call assert_equal('first', vlime#GetNthVarArg(['first', 'second'], 0, 'default'))
    call assert_equal('second', vlime#GetNthVarArg(['first', 'second'], 1, 'default'))
    call assert_equal('default', vlime#GetNthVarArg(['first', 'second'], 2, 'default'))
endfunction

function! TestSimpleSendCB()
    function! s:TestSimpleSendCBDummyCB(conn, msg)
        let b:vlime_test_send_cb_called_with_conn = a:conn
        let b:vlime_test_send_cb_called_with_msg = a:msg
    endfunction

    let conn = vlime#New()
    let b:vlime_test_send_cb_called_with_conn = v:null
    let b:vlime_test_send_cb_called_with_msg = v:null
    call vlime#SimpleSendCB(conn, function('s:TestSimpleSendCBDummyCB'),
                \ 'TestSimpleSendCB', v:null, s:OKReturn('reply'))
    call assert_equal(conn, b:vlime_test_send_cb_called_with_conn)
    call assert_equal('reply', b:vlime_test_send_cb_called_with_msg)
    unlet b:vlime_test_send_cb_called_with_conn
    unlet b:vlime_test_send_cb_called_with_msg
endfunction

function! TestConnectFailed()
    let conn = vlime#New()
    try
        call conn.Connect('127.0.0.1', 65535)
        call assert_false(v:true, 'Connect call did not fail')
    catch
        call assert_exception('vlime#Connect:')
    endtry
endfunction

function! TestIsConnected()
    let conn = vlime#New()
    call assert_false(conn.IsConnected())
endfunction

function! TestClose()
    let conn = vlime#New()
    try
        call conn.Close()
    catch
        call add(v:errors, v:exception)
    endtry
endfunction

function! TestGetCurrentPackage()
    function! s:DummyPackageGetter(...) dict
        return ['DUMMY-PACKAGE-1', 'DUMMY-PACKAGE-1']
    endfunction
    let ui = vlime#ui#New()
    let ui['GetCurrentPackage'] = function('s:DummyPackageGetter')
    let conn = vlime#New(v:null, ui)
    let pkg = conn.GetCurrentPackage()
    call assert_equal(['DUMMY-PACKAGE-1', 'DUMMY-PACKAGE-1'], pkg)
endfunction

function! TestSetCurrentPackage()
    function! s:DummyPackageSetter(pkg, ...) dict
        let b:vlime_test_dummy_package = a:pkg
    endfunction
    let ui = vlime#ui#New()
    let ui['SetCurrentPackage'] = function('s:DummyPackageSetter')
    let conn = vlime#New(v:null, ui)
    let b:vlime_test_dummy_package = v:null
    call conn.SetCurrentPackage(['DUMMY-PACKAGE-2', 'DUMMY-PACKAGE-2'])
    call assert_equal(['DUMMY-PACKAGE-2', 'DUMMY-PACKAGE-2'], b:vlime_test_dummy_package)
    unlet b:vlime_test_dummy_package
endfunction

function! TestGetCurrentThread()
    function! s:DummyThreadGetter(...) dict
        return {'name': 'REPL-THREAD', 'package': 'KEYWORD'}
    endfunction
    let ui = vlime#ui#New()
    let ui['GetCurrentThread'] = function('s:DummyThreadGetter')
    let conn = vlime#New(v:null, ui)
    let thread = conn.GetCurrentThread()
    call assert_equal({'name': 'REPL-THREAD', 'package': 'KEYWORD'}, thread)
endfunction

function! TestSetCurrentThread()
    function! s:DummyThreadSetter(thread, ...) dict
        let b:vlime_test_dummy_thread = a:thread
    endfunction
    let ui = vlime#ui#New()
    let ui['SetCurrentThread'] = function('s:DummyThreadSetter')
    let conn = vlime#New(v:null, ui)
    let b:vlime_test_dummy_thread = v:null
    call conn.SetCurrentThread({'name': 'DUMMY-THREAD', 'package': 'KEYWORD'})
    call assert_equal({'name': 'DUMMY-THREAD', 'package': 'KEYWORD'}, b:vlime_test_dummy_thread)
    unlet b:vlime_test_dummy_thread
endfunction

function! TestWithThread()
    function! s:DummyThreadGetter(...) dict
        return b:vlime_test_dummy_thread
    endfunction

    function! s:DummyThreadSetter(thread, ...) dict
        let b:vlime_test_dummy_thread = a:thread
    endfunction

    function! s:DummyAction(conn)
        let b:vlime_test_dummy_action_result = a:conn.GetCurrentThread()
    endfunction

    let ui = vlime#ui#New()
    let ui['GetCurrentThread'] = function('s:DummyThreadGetter')
    let ui['SetCurrentThread'] = function('s:DummyThreadSetter')
    let conn = vlime#New(v:null, ui)
    let b:vlime_test_dummy_thread = {'name': 'OLD-THREAD', 'package': 'KEYWORD'}
    let b:vlime_test_dummy_action_result = v:null
    call conn.WithThread(1, function('s:DummyAction', [conn]))
    call assert_equal(1, b:vlime_test_dummy_action_result)
    call assert_equal({'name': 'OLD-THREAD', 'package': 'KEYWORD'}, b:vlime_test_dummy_thread)
    unlet b:vlime_test_dummy_thread
    unlet b:vlime_test_dummy_action_result
endfunction

function! TestWithPackage()
    function! s:DummyPackageGetter(...) dict
        return b:vlime_test_dummy_package
    endfunction

    function! s:DummyPackageSetter(pkg, ...) dict
        let b:vlime_test_dummy_package = a:pkg
    endfunction

    function! s:DummyAction(conn)
        let b:vlime_test_dummy_action_result = a:conn.GetCurrentPackage()
    endfunction

    let ui = vlime#ui#New()
    let ui['GetCurrentPackage'] = function('s:DummyPackageGetter')
    let ui['SetCurrentPackage'] = function('s:DummyPackageSetter')
    let conn = vlime#New(v:null, ui)
    let b:vlime_test_dummy_package = ['OLD-PKG', 'OLD-PKG']
    let b:vlime_test_dummy_action_result = v:null
    call conn.WithPackage('NEW-PKG', function('s:DummyAction', [conn]))
    call assert_equal(['NEW-PKG','NEW-PKG'], b:vlime_test_dummy_action_result)
    call assert_equal(['OLD-PKG', 'OLD-PKG'], b:vlime_test_dummy_package)
    unlet b:vlime_test_dummy_package
    unlet b:vlime_test_dummy_action_result
endfunction

function! TestEmacsRex()
    let conn = vlime#New()
    let rex = conn.EmacsRex([{'package': 'SWANK', 'name': 'CONNECTION-INFO'}])
    call assert_equal([
                    \ {'package': 'KEYWORD', 'name': 'EMACS-REX'},
                    \ [{'package': 'SWANK', 'name': 'CONNECTION-INFO'}],
                    \ v:null, v:true],
                \ rex)
endfunction

function! TestOnServerEvent()
    function! s:DummyPingHandler(chan, msg)
        let b:vlime_test_ping_handler_called = v:true
    endfunction

    let conn = vlime#New()
    let conn['server_event_handlers']['PING'] = function('s:DummyPingHandler')
    let b:vlime_test_ping_handler_called = v:false
    call conn.OnServerEvent(v:null, [{'name': 'PING', 'package': 'KEYWORD'}, 1, 42])
    call assert_true(b:vlime_test_ping_handler_called)
    unlet b:vlime_test_ping_handler_called
endfunction

function! s:SYM(package, name)
    return {'name': a:name, 'package': a:package}
endfunction

function! s:KW(name)
    return s:SYM('KEYWORD', a:name)
endfunction

" s:ExpectedEmacsRex(package, name[, args...])
function! s:ExpectedEmacsRex(package, name, ...)
    return [s:KW('EMACS-REX'),
                \ [s:SYM(a:package, a:name)] + a:000,
                \ v:null, v:true]
endfunction

function! s:OKReturn(result)
    return [s:KW('RETURN'), [s:KW('OK'), a:result]]
endfunction

" TestMessage(name, expected, reply[, args...])
function! TestMessage(name, expected, reply, ...)
    function! s:TestMessageDummySend(dummy_conn, dummy_reply, msg, ...) dict
        call assert_true(a:0 == 0 || a:0 == 1)
        let b:vlime_test_dummy_sent_msg = a:msg
        if a:0 == 1
            let CB = function(a:1, [a:dummy_conn, a:dummy_reply])
            call CB()
        endif
    endfunction

    let conn = vlime#New()
    let conn['Send'] = function('s:TestMessageDummySend', [conn, a:reply])
    let ToCall = function(conn[a:name], a:000)
    let b:vlime_test_dummy_sent_msg = v:null
    call ToCall()
    call assert_equal(a:expected, b:vlime_test_dummy_sent_msg)
    unlet b:vlime_test_dummy_sent_msg
    return conn
endfunction

let v:errors = []
call TestGetNthVarArg()
call TestSimpleSendCB()
call TestConnectFailed()
call TestIsConnected()
call TestClose()
call TestGetCurrentPackage()
call TestSetCurrentPackage()
call TestGetCurrentThread()
call TestSetCurrentThread()
call TestWithThread()
call TestWithPackage()
call TestEmacsRex()
call TestOnServerEvent()

" [msg_name, expected, dummy_reply, args...]
let b:messages_to_test = [
            \ ['Pong', [s:KW('EMACS-PONG'), 1, 42], v:null, 1, 42],
            \ ['ConnectionInfo',
                \ s:ExpectedEmacsRex('SWANK', 'CONNECTION-INFO'),
                \ s:OKReturn([s:KW('PID'), 1234]),
                \ v:true],
            \ ['SwankRequire',
                \ s:ExpectedEmacsRex('SWANK', 'SWANK-REQUIRE', s:KW('DUMMY-MODULE')),
                \ s:OKReturn(['DUMMY-MODULE']),
                \ 'DUMMY-MODULE'],
            \ ['SwankRequire',
                \ s:ExpectedEmacsRex('SWANK', 'SWANK-REQUIRE',
                    \ [s:SYM('COMMON-LISP', 'QUOTE'),
                        \ [s:KW('DUMMY-MODULE-1'), s:KW('DUMMY-MODULE-2')]]),
                \ s:OKReturn(['DUMMY-MODULE']),
                \ ['DUMMY-MODULE-1', 'DUMMY-MODULE-2']],
            \ ['CreateREPL',
                \ s:ExpectedEmacsRex('SWANK-REPL', 'CREATE-REPL', v:null),
                \ s:OKReturn(['COMMON-LISP-USER', 'CL-USER'])],
            \ ['CreateREPL',
                \ s:ExpectedEmacsRex('SWANK-REPL', 'CREATE-REPL', v:null, s:KW('CODING-SYSTEM'), 'UTF-8'),
                \ s:OKReturn(['COMMON-LISP-USER', 'CL-USER']),
                \ 'UTF-8'],
            \ ['ListenerEval',
                \ s:ExpectedEmacsRex('SWANK-REPL', 'LISTENER-EVAL', 'expression'),
                \ s:OKReturn(['COMMON-LISP-USER', 'CL-USER']),
                \ 'expression'],
            \ ['Interrupt',
                \ [s:KW('EMACS-INTERRUPT'), 1],
                \ v:null,
                \ 1],
            \ ['SLDBAbort',
                \ s:ExpectedEmacsRex('SWANK', 'SLDB-ABORT'),
                \ s:OKReturn(v:null)],
            \ ['SLDBBreak',
                \ s:ExpectedEmacsRex('SWANK', 'SLDB-BREAK', 'func_name'),
                \ s:OKReturn(v:null),
                \ 'func_name'],
            \ ['SLDBContinue',
                \ s:ExpectedEmacsRex('SWANK', 'SLDB-CONTINUE'),
                \ s:OKReturn(v:null)],
            \ ['SLDBStep',
                \ s:ExpectedEmacsRex('SWANK', 'SLDB-STEP', 0),
                \ s:OKReturn(v:null),
                \ 0],
            \ ['SLDBNext',
                \ s:ExpectedEmacsRex('SWANK', 'SLDB-NEXT', 0),
                \ s:OKReturn(v:null),
                \ 0],
            \ ['SLDBOut',
                \ s:ExpectedEmacsRex('SWANK', 'SLDB-OUT', 0),
                \ s:OKReturn(v:null),
                \ 0],
            \ ['SLDBReturnFromFrame',
                \ s:ExpectedEmacsRex('SWANK', 'SLDB-RETURN-FROM-FRAME', 0, 'expression'),
                \ s:OKReturn(v:null),
                \ 0, 'expression'],
            \ ['SLDBDisassemble',
                \ s:ExpectedEmacsRex('SWANK', 'SLDB-DISASSEMBLE', 0),
                \ s:OKReturn(v:null),
                \ 0],
            \ ['InvokeNthRestartForEmacs',
                \ s:ExpectedEmacsRex('SWANK', 'INVOKE-NTH-RESTART-FOR-EMACS', 1, 0),
                \ s:OKReturn(v:null),
                \ 1, 0],
            \ ['RestartFrame',
                \ s:ExpectedEmacsRex('SWANK', 'RESTART-FRAME', 0),
                \ s:OKReturn(v:null),
                \ 0],
            \ ['FrameLocalsAndCatchTags',
                \ s:ExpectedEmacsRex('SWANK', 'FRAME-LOCALS-AND-CATCH-TAGS', 0),
                \ s:OKReturn(v:null),
                \ 0],
            \ ['FrameSourceLocation',
                \ s:ExpectedEmacsRex('SWANK', 'FRAME-SOURCE-LOCATION', 0),
                \ s:OKReturn([s:KW('LOCATION'),
                    \ [s:KW('FILE'), 'dummy_file.lisp'],
                    \ [s:KW('POSITION'), 1],
                    \ [s:KW('SNIPPET'), "snippet"]]),
                \ 0],
            \ ['EvalStringInFrame',
                \ s:ExpectedEmacsRex('SWANK', 'EVAL-STRING-IN-FRAME', 'expression', 0, 'DUMMY-PACKAGE'),
                \ s:OKReturn(v:null),
                \ 'expression', 0, 'DUMMY-PACKAGE'],
            \ ['InitInspector',
                \ s:ExpectedEmacsRex('SWANK', 'INIT-INSPECTOR', 'expression'),
                \ s:OKReturn(v:null),
                \ 'expression'],
            \ ['InspectorReinspect',
                \ s:ExpectedEmacsRex('SWANK', 'INSPECTOR-REINSPECT'),
                \ s:OKReturn(v:null)],
            \ ['InspectorRange',
                \ s:ExpectedEmacsRex('SWANK', 'INSPECTOR-RANGE', 0, 500),
                \ s:OKReturn(v:null),
                \ 0, 500],
            \ ['InspectNthPart',
                \ s:ExpectedEmacsRex('SWANK', 'INSPECT-NTH-PART', 0),
                \ s:OKReturn(v:null),
                \ 0],
            \ ['InspectorCallNthAction',
                \ s:ExpectedEmacsRex('SWANK', 'INSPECTOR-CALL-NTH-ACTION', 0),
                \ s:OKReturn(v:null),
                \ 0],
            \ ['InspectorPop',
                \ s:ExpectedEmacsRex('SWANK', 'INSPECTOR-POP'),
                \ s:OKReturn(v:null)],
            \ ['InspectCurrentCondition',
                \ s:ExpectedEmacsRex('SWANK', 'INSPECT-CURRENT-CONDITION'),
                \ s:OKReturn(v:null)],
            \ ['InspectInFrame',
                \ s:ExpectedEmacsRex('SWANK', 'INSPECT-IN-FRAME', 'expression', 0),
                \ s:OKReturn(v:null),
                \ 'expression', 0],
            \ ['SetPackage',
                \ s:ExpectedEmacsRex('SWANK', 'SET-PACKAGE', 'dummy-package'),
                \ s:OKReturn(v:null),
                \ 'dummy-package'],
            \ ['DescribeSymbol',
                \ s:ExpectedEmacsRex('SWANK', 'DESCRIBE-SYMBOL', 'symbol'),
                \ s:OKReturn(v:null),
                \ 'symbol'],
            \ ['OperatorArgList',
                \ s:ExpectedEmacsRex('SWANK', 'OPERATOR-ARGLIST', 'operator', v:null),
                \ s:OKReturn(v:null),
                \ 'operator'],
            \ ['SimpleCompletions',
                \ s:ExpectedEmacsRex('SWANK', 'SIMPLE-COMPLETIONS', 'symbol', v:null),
                \ s:OKReturn(v:null),
                \ 'symbol'],
            \ ['FuzzyCompletions',
                \ s:ExpectedEmacsRex('SWANK', 'FUZZY-COMPLETIONS', 'symbol', v:null),
                \ s:OKReturn(v:null),
                \ 'symbol'],
            \ ['ReturnString',
                \ [s:KW('EMACS-RETURN-STRING'), 1, 42, 'returned'],
                \ v:null,
                \ 1, 42, 'returned'],
            \ ['Return',
                \ [s:KW('EMACS-RETURN'), 1, 42, 'returned'],
                \ v:null,
                \ 1, 42, 'returned'],
            \ ['SwankMacroExpandOne',
                \ s:ExpectedEmacsRex('SWANK', 'SWANK-MACROEXPAND-1', 'expression'),
                \ s:OKReturn(v:null),
                \ 'expression'],
            \ ['SwankMacroExpand',
                \ s:ExpectedEmacsRex('SWANK', 'SWANK-MACROEXPAND', 'expression'),
                \ s:OKReturn(v:null),
                \ 'expression'],
            \ ['SwankMacroExpandAll',
                \ s:ExpectedEmacsRex('SWANK', 'SWANK-MACROEXPAND-ALL', 'expression'),
                \ s:OKReturn(v:null),
                \ 'expression'],
            \ ['DisassembleForm',
                \ s:ExpectedEmacsRex('SWANK', 'DISASSEMBLE-FORM', 'expression'),
                \ s:OKReturn(v:null),
                \ 'expression'],
            \ ['CompileStringForEmacs',
                \ s:ExpectedEmacsRex('SWANK', 'COMPILE-STRING-FOR-EMACS',
                    \ 'expression', 1, [s:SYM('COMMON-LISP', 'QUOTE'), [[s:KW('POSITION'), 1]]],
                    \ 'filename', v:null),
                \ s:OKReturn(v:null),
                \ 'expression', 1, 1, 'filename'],
            \ ['CompileStringForEmacs',
                \ s:ExpectedEmacsRex('SWANK', 'COMPILE-STRING-FOR-EMACS',
                    \ 'expression', 1, [s:SYM('COMMON-LISP', 'QUOTE'), [[s:KW('POSITION'), 1]]],
                    \ 'filename',
                    \ [s:SYM('COMMON-LISP', 'QUOTE'),
                        \ [{'head': [s:SYM('COMMON-LISP', 'DEBUG')], 'tail': 3}]]),
                \ s:OKReturn(v:null),
                \ 'expression', 1, 1, 'filename', {'DEBUG': 3}],
            \ ['CompileFileForEmacs',
                \ s:ExpectedEmacsRex('SWANK', 'COMPILE-FILE-FOR-EMACS', 'filename', v:true),
                \ s:OKReturn(v:null),
                \ 'filename'],
            \ ['LoadFile',
                \ s:ExpectedEmacsRex('SWANK', 'LOAD-FILE', 'filename'),
                \ s:OKReturn(v:null),
                \ 'filename'],
            \ ['XRef',
                \ s:ExpectedEmacsRex('SWANK', 'XREF', s:KW('CALLS'), 'symbol'),
                \ s:OKReturn(v:null),
                \ 'CALLS', 'symbol'],
            \ ['FindDefinitionsForEmacs',
                \ s:ExpectedEmacsRex('SWANK', 'FIND-DEFINITIONS-FOR-EMACS', 'symbol'),
                \ s:OKReturn(v:null),
                \ 'symbol'],
            \ ['AproposListForEmacs',
                \ s:ExpectedEmacsRex('SWANK', 'APROPOS-LIST-FOR-EMACS',
                    \ 'symbol', v:false, v:false, 'DUMMY-PACKAGE'),
                \ s:OKReturn(v:null),
                \ 'symbol', v:false, v:false, 'DUMMY-PACKAGE'],
            \ ['DocumentationSymbol',
                \ s:ExpectedEmacsRex('SWANK', 'DOCUMENTATION-SYMBOL', 'symbol'),
                \ s:OKReturn(v:null),
                \ 'symbol'],
        \ ]

for msg_spec in b:messages_to_test
    let ToCall = function('TestMessage', msg_spec)
    call ToCall()
endfor
