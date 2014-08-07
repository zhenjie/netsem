(* ---------------------------------------------------------------------- *)
(* Netsem Tthee Automated Tests Code: getsockbopt()/setsockbopt()         *)
(* Steve Bishop - Created 20030702                                        *)
(* $Id: sockbopt.ml,v 1.12 2006/06/19 11:57:45 amgb2 Exp $ *)
(* ---------------------------------------------------------------------- *)

(* Ocaml libraries *)
open Thread
open Printf

(* Our libraries *)
open Nettypes
open Tthee
open Ttheehelper
open Ocamllib
open Libcalls
open Common
open Dual
open Dualdriven
open Common_udp
open Dualdriven_udp
open Testscommon
(* ---------------------------------------------------------------------- *)

let test1 = function (so, so_descr) -> (
  (function id -> function ts ->
    let fd = get_socket (the ts.th_libd_hnd) in
    let get_call = (tid_of_int_private 0, GETSOCKBOPT(fd, so)) in
    ignore(libd_call (the ts.th_libd_hnd) get_call);
    let set_call_f = (tid_of_int_private 0, SETSOCKBOPT(fd, so, false)) in
    ignore(libd_call (the ts.th_libd_hnd) set_call_f);
    ignore(libd_call (the ts.th_libd_hnd) get_call);
    let set_call_t = (tid_of_int_private 0, SETSOCKBOPT(fd, so, true)) in
    ignore(libd_call (the ts.th_libd_hnd) set_call_t);
    ignore(libd_call (the ts.th_libd_hnd) get_call)),
  "getsockbopt()/setsockbopt() -- for a fresh TCP socket, call getsockbopt(), setsockbopt(false), getsockopt(), setsockbopt(true) and finally, getsockopt(), for the socket option " ^ so_descr,
  ((true, false), true, true, false),
  ((false, false), false, false, false)
 )

let test2 = function (so, so_descr) -> (
  (function id -> function ts ->
    let fd = get_socket_udp (the ts.th_libd_hnd) in
    let get_call = (tid_of_int_private 0, GETSOCKBOPT(fd, so)) in
    ignore(libd_call (the ts.th_libd_hnd) get_call);
    let set_call_f = (tid_of_int_private 0, SETSOCKBOPT(fd, so, false)) in
    ignore(libd_call (the ts.th_libd_hnd) set_call_f);
    ignore(libd_call (the ts.th_libd_hnd) get_call);
    let set_call_t = (tid_of_int_private 0, SETSOCKBOPT(fd, so, true)) in
    ignore(libd_call (the ts.th_libd_hnd) set_call_t);
    ignore(libd_call (the ts.th_libd_hnd) get_call);
    rst_udp_socket id ts fd),
  "getsockbopt()/setsockbopt() -- for a fresh UDP socket, call getsockbopt(), setsockbopt(false), getsockopt(), setsockbopt(true) and finally, getsockopt(), for the socket option " ^ so_descr,
  ((true, false), true, false, false),
  ((false, false), false, false, true)
 )

let tcp_tests = List.map (function so -> test1 so)
    [(SO_REUSEADDR, "SO_REUSEADDR"); (SO_KEEPALIVE, "SO_KEEPALIVE");
     (SO_OOBINLINE, "SO_OOBINLINE"); (SO_DONTROUTE, "SO_DONTROUTE");]

let udp_tests = List.map (function so -> test2 so)
    [(SO_REUSEADDR, "SO_REUSEADDR"); (SO_KEEPALIVE, "SO_KEEPALIVE");
     (SO_OOBINLINE, "SO_OOBINLINE"); (SO_DONTROUTE, "SO_DONTROUTE");]

let normal_tests = tcp_tests @ udp_tests

let tcp_exhaustive_tests = []
let udp_exhaustive_tests = []
let exhaustive_tests = tcp_exhaustive_tests @ udp_exhaustive_tests

let stream_tests = tcp_tests
let stream_exhaustive_tests = tcp_exhaustive_tests

(* ---------------------------------------------------------------------- *)

let do_sockbopt_tests handle hosts_list test_type =
  begin_next_test_group handle "getsockbopt()/setsockbopt()";
  let done_a_test = ref false in
  let num_of_tests = ref 0 in

  let tests = match test_type with
    TCP_NORMAL -> tcp_tests
  | UDP_NORMAL -> udp_tests
  | ALL_NORMAL -> normal_tests
  | TCP_EXHAUSTIVE -> tcp_exhaustive_tests
  | UDP_EXHAUSTIVE -> udp_exhaustive_tests
  | ALL_EXHAUSTIVE -> exhaustive_tests
  | STREAM_NORMAL -> stream_tests
  | STREAM_EXHAUSTIVE -> stream_exhaustive_tests in

  List.iter
    (function host ->
      List.iter
	(function (test_thunk, descr, thts, ahts) ->
	  let _ =
	    (if(!num_of_tests = 10) then
	      let _ =  num_of_tests := 0 in
	      ntp_update 60.0) in
	  let rec do_test test_thunk descr thts ahts n =
	    try
	      if not(skip_test handle) then
		let _ = done_a_test := true in
		let test_fname = fmt_fname handle !trace_name_number_size in
		let id = {
		  tthee_host = handle.tthee_host_ip;
		  virtual_host_ip = handle.vhost_ip;
		  virtual_host_port = handle.vhost_port;
		  seq_fname = test_fname;
		  test_descr = (test_type_str test_type) ^ " " ^ descr;

		  test_host = host;
		  test_host_tools = thts;
		  test_host_bound = [];

		  aux_host = pick_any_other_host hosts_list host;
		  aux_host_tools =  ahts;
		  aux_host_bound = [];
		} in

		let ts = dual_tthee_init id debug_OFF !tthee_baseport_1
		    !tthee_baseport_2 !merger_delta in
		let _ =
		  try test_thunk id ts
		  with e -> report_test_failure handle descr e
		in

		dual_tthee_cleanup ts
	      else ();
	      next_test handle
	    with Unix.Unix_error(e,_,_) ->
	      if n = 0 then raise (Test_failed ("Unix_error:" ^ (Unix.error_message e)))
	      else
		(delay (float_of_int (n * 30));
		 do_test test_thunk descr thts ahts (n-1)) in
	  do_test test_thunk descr thts ahts 10;
	  if host.platform_type = ARCH_WINXP then num_of_tests := !num_of_tests + 1;)
	tests
    )
    hosts_list;
  !done_a_test

(* ---------------------------------------------------------------------- *)
(* -*-*- THE END -*-*- *)
(* ---------------------------------------------------------------------- *)
