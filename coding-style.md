== General ==
# Do not modify standard code in warehouse branches unless you have to. This bloats your commits and increases the chance of conflicts.
# Code, traces, comments and commit messages are written in English.
# Avoid special characters in code.
# Avoid unused variables/constants/methods.
# Use ''make check'' (up to One 2.3: ''ant check'') to find some coding style violations.
# Identifier length (variables, parameters, table names, column names, ...)
#* < 2.5: Limited to 30 characters for compatibility with Oracle 12.1
#* ≥ 2.5: Limit removed, stay within 30 characters if comfortably possible

== Best practices (KiSoft One) ==
=== Object types ===
# Avoid <font face="Courier"><object-type>.get_object()</font> if you don't need the sub-objects
#* This loads the whole object from the object-view, also containing all referenced entities that are configured for it, recursively.<br>For ''order_ot'', this is:
#** ''customer'' ( ''customer_property'' )
#** ''document''
#** ''loading_unit'' ( ''loading_unit_info'', ''stock'' ( ''stock_info'', ''stock_lock'' ) )
#** ''order_info''
#** ''order_line'' ( ''order_allocation'' )
#** ''order_property''
#** ''order_ramp''
#** ''order_weight''
#** ''order_work_task''
#** ''route'' ( ''route_customer'', ''route_property'', ''route_ramp'' )
#* There is no need to load the whole object before ''ustore''. It just updates the fields that are not NULL and keeps the rest.

=== Transactions ===
# Avoid transaction handling (COMMIT, ROLLBACK) in PL/SQL code
#* Allow the caller to handle the transaction, that also allows to rollback after unit-tests
#* Exceptions (rare) for
#** huge bulk processing where you might need to COMMIT after n rows
#** handling a list of objects where an error with one entry should lead to a rollback to a previously defined SAVEPOINT, allowing to process the rest of the entities
#** Long running transactions that trigger events (write into AQs) or cause locks and cannot be made faster.<br>Make sure that your code still works as expected if an exception happens after a part of the changes have been commited.

=== Database jobs ===
# Do not use (neither old jobs nor scheduler-jobs).<br>Use a ''minion'' instead, or a new ''process'' if necessary.
#* Jobs are not stopped when stopping the system and can cause problems.
#* Jobs had some bugs that we do not need to deal with

=== Triggers ===
# Never used for logistical reasons and almost never for technical reasons like enforcing data integrity

== Format ==
=== Spacing ===
# Limit a single line to 140 characters where possible.

=== Indentation ===
# Use 2 spaces, no tabs
# Use 4 spaces for consecutive lines of procedure-, function- and constructor-calls and string concatenations
# Use 2 spaces before closing parenthesis of multi-line method calls
# No trailing spaces in source files

; Alignment
# Avoid having to edit all the other lines when a longer identifier comes along by aligning at the 31st character<br>('''≥ One 2.5''': The limit was removed, still start with space for 30 characters and extend when necessary)
#* Data type in variable declaration
#* Keyword CONSTANT in constant declaration
#* IN/OUT modifiers of method parameters
#* "=>" of named parameters in method calls
#* A list of WHEN clauses in a CASE statement can also benefit from this when using lookups (see example below)
# Data types after IN/OUT modifiers are *not* aligned – "IN OUT NOCOPY" is too long to always reserve that space.

; Example
<syntaxhighlight lang="plsql">
  ------------------------------------------------------------------------------
  PROCEDURE move_stock_and_allocation(
    in_source_stock_id             IN stock.stock_id%TYPE,                                -- 31 character alignment for parameter mode
    in_order_id                    IN order_line.order_id%TYPE,                           -- parameter type is NOT aligned (only one space after IN)
    in_order_line_id               IN order_line.line_id%TYPE,
    io_work_event_target           IN OUT NOCOPY work_event_ot,
    out_error_code                 OUT error_code.token%TYPE
  )
  AS
    log                            CONSTANT log_ot := NEW log_ot( c_module_name, 'move_stock_and_allocation' );
  BEGIN
    log.notice( 'Move stock_id <' || in_source_stock_id || '> and allocation for order_id <'
        || in_order_id || '> line_id <' || in_order_line_id || '> with work_event: '      -- 4 spaces for consecutive lines
        || io_work_event_target.to_str()
      );

    stock_handler.move_stock(
        in_source_stock_id             => in_source_stock_id,                             -- 31 character alignment for "=>"
        io_work_event_target           => io_work_event_target,
        out_error_code                 => out_error_code
      );                                                                                  -- 2 spaces for closing parenthesis

    ...

  END move_stock_and_allocation;
</syntaxhighlight>

<syntaxhighlight lang="plsql">
    -- Parameters of multi-line function calls and constructors are also aligned at 4 spaces
    v_work_event := NEW work_event_ot(
        in_work_event_id               => NULL,
        ...
        in_free_text                   => in_free_text
      );
</syntaxhighlight>

<syntaxhighlight lang="plsql">
CASE io_order.host_order_type_id
  --          [        31 characters          ]  Length of actual lookup name cannot exceed 30 characters (before One 2.5) so this allows to add others without reformatting
  WHEN lu.hoty.goodsin_osr_open               THEN lu.buc.goods_in
  WHEN lu.hoty.cd1_inbound_delivery           THEN lu.buc.inventory
  ...

</syntaxhighlight>

=== Parentheses ===
# Parentheses are always used for IF conditions.
# Parentheses are also used for method calls and object type constructors without parameters.

; Example
<syntaxhighlight lang="plsql">
  IF( v_order IS NULL ) THEN
    v_order := NEW order_ot();
  END IF;
</syntaxhighlight>

=== Whitespace ===
; Rules
# No space within the parenthesis of variable/constant declarations:
#* Example: <font face="Courier">VARCHAR2(1024)</font>
#* Avoid hardcoded lengths if you can use a column reference instead: <font face="Courier">orders.order_nr%TYPE</font>
# Space after the opening and before the closing parentheses of method calls, IF, WHEN and WHILE statements and when accessing elements of collections. Empty parentheses contain no spaces though.
# No space between IF/WHILE/WHEN and opening parenthesis, space between closing parenthesis and THEN/LOOP

; Example
<syntaxhighlight lang="plsql">
  v_orl_idx := v_order_lines.FIRST();                                                     -- parentheses without space
  WHILE( v_orl_idx IS NOT NULL ) LOOP                                                     -- spaces within parentheses of WHILE
    IF( v_order_lines( v_orl_idx ).line_status_id = lu.ols.cancelled ) THEN               -- spaces within parentheses of IF and for accessing nested table
      log.info( 'line_id <' || v_order_lines( v_orl_idx ).line_id || '> is cancelled' );  -- spaces within parentheses of method call
    END IF;
    v_orl_idx := v_order_lines.NEXT( v_orl_idx );                                         -- spaces within parentheses since this is also a method call
  END LOOP;
</syntaxhighlight>

=== Multi-line conditions and cursors ===
; Rules
# Corresponding keyword (THEN, LOOP) is on a separate line, using the same indentation as the opening keyword.
# Opening and closing parenthesis are in-line for IF statements but get their own lines for cursors since these are usually much more complex

; Example
<syntaxhighlight lang="plsql">
  IF(     v_order.order_type_id = lu.ort.classic
      AND v_order.loading_unit_id IS NOT NULL )
  THEN                                                                                    -- separate line
    ...
  END IF;
</syntaxhighlight>

<syntaxhighlight lang="plsql">
  FOR cur_orl IN
  (
      SELECT orl.line_id
        FROM order_line orl
       WHERE orl.order_id = in_order_id
       ORDER BY orl.line_id
  )
  LOOP
    ...
  END LOOP;
</syntaxhighlight>

=== Case ===
# Variables, method-, and package names und constants(!) are lowercase
# Schema-, table- and column-names are lowercase
# Oracle keywords are uppercase (for example<font face="Courier"> BEGIN, CONSTANT, CREATE, END, FOR, FROM, GROUP, IF, IN, INDEX, LOOP, NEW, NUMBER, OR, REPLACE, RETURN, ROWCOUNT, SELECT, AS, UPDATE, WHERE, WHILE</font>).
# Oracle built-in primitive data-types are uppercase (for example<font face="Courier"> NUMBER, VARCHAR2, PLS_INTEGER</font>).
# Words separated by underscore "_"
# Trace/comments: In English, unlike German, most words are lowercase :)

=== Prefix ===
# Variables: <font face="Courier">v_</font>
# Constants: <font face="Courier">c_</font>
# Parameters: <font face="Courier">in_, out_, io_</font> (for <font face="Courier">IN, OUT</font> und <font face="Courier">IN OUT</font> respectively)
# Cursors: <font face="Courier">cur_</font>
# User defined types: <font face="Courier">t_</font>


=== Operators ===
# The not equals operator <font face="Courier"><></font> is used according to the ANSI standard (not <font face="Courier">!=</font>)

=== Initialization ===
# Variables and constants are initialized using <font face="Courier">:=</font>, never <font face="Courier">DEFAULT</font>
# Default parameters are initialized using <font face="Courier">DEFAULT</font>, never <font face="Courier">:=</font>
# Do not initialize variables to <font face="Courier">NULL</font> (default value anyways)
# Use the keyword <font face="Courier">NEW</font> for object type constructors

; Example
<syntaxhighlight lang="plsql">
  PROCEDURE test_me(
    in_line_count                  IN PLS_INTEGER DEFAULT 1                               -- use DEFAULT, not :=
  )
  AS
    c_order_type_id                CONSTANT orders.order_type_id%TYPE := lu.ort.movement; -- use := not DEFAULT
    v_order                        order_type_ot := NEW order_type_ot();                  -- use NEW and parenthesis
  BEGIN
    ...
</syntaxhighlight>

=== Subprogram parameter modes ===
# Mode is always provided: IN / OUT / IN OUT
# Keyword <font face="Courier">NOCOPY</font> for all <font face="Courier">IN OUT</font> parameters unless there is a good reason against it
# Sort parameters where it makes sense: IN before IN OUT before OUT

; Example
<syntaxhighlight lang="plsql">
PROCEDURE test_me(
  in_order_type_id               IN orders.order_type_id%TYPE,
  io_order                       IN OUT NOCOPY order_ot,
  out_error_code                 OUT error_code.token%TYPE
)
</syntaxhighlight>

== Style ==

=== General ===
# Use constants instead of magic numbers.
# Use meaningful names for tables, views, columns, packages, methods and variables.
#* ''start_station'''_id''''' instead of ''start_station''
#* ''v_process_status_id'' instead of ''v_status''
#* ''v_product_bundle_flag'''_key_ids''''' instead of ''v_product_bundle_flags''<br>
# Avoid unnecessary abbreviations for tables, views, columns, packages, methods and variables.
#* ''v_order_id'' instead of ''v_ord_id''<br>
#* ''v_order_start_capacity.sql'' instead of ''v_ord_start_cap.sql''
# Split large packages/methods into smaller packages/methods when it makes sense.
# Ampersand (''&'') shouldn't be used in SQL files, not even in comments. SQL*Plus uses it to replace variables.


=== Headers ===
# Package header
#* Copyright message + description
#* The header is located after the <font face="Courier">CREATE OR REPLACE … AS</font>, so that it persists when replacing.
# Method header
#* Describe
#** what the method does
#** parameters (<font face="Courier">@param</font>)
#** return value for functions (<font face="Courier">@returns</font>)
#** expected exceptions (<font face="Courier">@throws</font>)
#* Descriptions of "public" methods are only located in the package header.
#* When relevant, describe "private" methods in the body.
# ''RETURN'' clause in function declaration is on a separate line and indented 2 spaces.

=== Structure ===
# Use the same order for public methods in the package header and the body.
# Write private methods before public methods to avoid problems with dependencies.
# Methods are visually separated with
#* two newlines
#* a dashed separator line
#* method comments

; Example

<syntaxhighlight lang="plsql">
CREATE OR REPLACE PACKAGE klassx.stock_handler
AS
/* -*- sql -*-************************************************************
 *                                                                       *
 *                      Copyright (C) KNAPP AG                           *
 *                                                                       *
 *    The copyright to the computer program(s) herein is the property    *
 *    of Knapp.  The program(s) may be used   and/or copied only with    *
 *    the  written permission of  Knapp  or in  accordance  with  the    *
 *    terms and conditions stipulated in the agreement/contract under    *
 *    which the program(s) have been supplied.                           *
 *                                                                       *
 *************************************************************************/


  ------------------------------------------------------------------------------
  -- Query if a certain stock_info is set on a stock
  -- @param in_stock_id stock to check
  -- @param in_stock_info_key_id stock_info to check
  -- @returns TRUE if the stock_info is set
  FUNCTION has_stock_info(
    in_stock_id                    IN stock_info.stock_id%TYPE,
    in_stock_info_key_id           IN stock_info.stock_info_key_id%TYPE
  )
    RETURN BOOLEAN;
</syntaxhighlight>

=== Method calls ===
# Use named parameter notation (=>) whenever it helps with readability, especially for everything with more than three parameters.

; Example
<syntaxhighlight lang="plsql">
  -- little room for confusion here, keep it simple
  stock_handler.add_stock_info( v_stock_id, lu.slr.lost );

  -- easier to read and less error prone with named parameters
  stock_handler.correct_stock(
      in_stock_id                    => c.stock_id,
      in_new_quantity                => v_new_stock_quantity,
      in_user_code                   => in_name,
      in_standard_text_id            => lu.stte.system,
      out_error_code                 => v_error_code
    );
</syntaxhighlight>


=== Exceptions ===
# Handle exceptions as locally as possible. Do not put a <font face="Courier">NO_DATA_FOUND</font> at the end of procedures with several queries, handle in an explicit ''BEGIN/END'' block.<br>If that makes your code hard to read, consider extracting such a query/code block with the exception handling into a separate method.
# Use <font face="Courier">log.exc</font> to trace exceptions where you need the stacktrace (not for expected exceptions like <font face="Courier">NO_DATA_FOUND</font>).
# No <font face="Courier">WHEN OTHERS</font> without <font face="Courier">RAISE</font>.<br>Usually no <font face="Courier">WHEN OTHERS</font> at all. Catch the exceptions that you can handle.<br>'''Definitely no''' <font face="Courier">WHEN OTHERS THEN NULL</font>.
# In the rare case where <font face="Courier">WHEN OTHERS</font> without <font face="Courier">RAISE</font> is used, we need to pass some critical exceptions back to the client:
#* <font face="Courier">util_exception.is_reraise_expected()</font>
#* before One 2.2: <font face="Courier">WHEN util_exception.program_unit_lost</font>

; Example
<syntaxhighlight lang="plsql">
  EXCEPTION
    WHEN OTHERS THEN
      log.exc( 'Failed, order_id <' || in_order_id || '>' );

      IF( util_exception.is_reraise_expected() ) THEN
        RAISE;
      END IF;
  END test_procedure;
</syntaxhighlight>

; Example (before One 2.2)
<syntaxhighlight lang="plsql">
  EXCEPTION
    WHEN util_exception.program_unit_lost THEN
      log.exc( 'Failed, order_id <' || in_order_id || '>' );
      RAISE;
    WHEN OTHERS THEN
      log.exc( 'Failed, order_id <' || in_order_id || '>' );
  END test_procedure;
</syntaxhighlight>

=== Traces ===
# Declare <font face="Courier">c_module_name</font> in the PACKAGE BODY. This helps to avoid exceptions after recompilation.
#* Preferred:<br><font face="Courier">c_module_name&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;CONSTANT DBMS_ID := LOWER( $$PLSQL_UNIT );</font>
#* Accepted:<br><font face="Courier">c_module_name&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;CONSTANT VARCHAR2(30) := LOWER( $$PLSQL_UNIT );</font>
# Trace parameters and variables in angle brackets
#* Example: <font face="Courier">in_order_id <123456> v_product_code <TESTCODE></font>
# To trace all set fields of an object type use <font face="Courier">.to_str()</font>
# Use <font face="Courier">to_trc</font> of lookups in traces:
#* Example: <font face="Courier">'order_type_id <' || lu.ort.to_trc( v_order_type_id ) || '>'</font><br>Result: <font face="Courier">order_type_id <1/CLASSIC></font>
# Make sure to trace all IN and OUT parameters / return values at least once
#* For simple methods like getters it makes more sense to have only one line of trace, containing all parameters and return values (also in case of a handled exception)
#* For more complex methods, trace the IN parameters at the start and the return values at the end (if possible together with the IN parameters)
# Unexpected exceptions are traced with <font face="Courier">log.exc</font> (<font face="Courier">log_d.exc</font>). The logger then writes the messages as ''ERROR'' and the stacktrace is automatically added.

; Examples
<syntaxhighlight lang="plsql">
  ------------------------------------------------------------------------------
  FUNCTION get_business_case_id(
    in_order_id                    IN orders.order_id%TYPE
  )
    RETURN orders.business_case_id%TYPE
  AS
    log                            CONSTANT log_ot := NEW log_ot( c_module_name, 'get_business_case_id' );
    v_business_case_id             orders.business_case_id%TYPE;
  BEGIN
                                                                                                                    -- Simple getter, no need for additional trace here
    SELECT business_case_id
      INTO v_business_case_id
      FROM orders
     WHERE order_id = in_order_id;

    log.debug( 'Returning business_case_id <' || lu.buc.to_trc( v_business_case_id )
        || '> for order_id <' || in_order_id || '>'                                                                 -- Trace all parameters and return values
      );

    RETURN v_business_case_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      log.warning( 'Failed, order_id <' || in_order_id || '> not found. Return <>' );                               -- Also trace all parameters and return values here
      RETURN NULL;
  END get_business_case_id;
</syntaxhighlight>

=== Comments ===
# Use <font face="Courier" color="green">--</font> for comments instead of <font face="Courier" color="green">/*</font> and <font face="Courier" color="green">*/</font>. This allows to comment out bigger blocks using <font face="Courier" color="green">/* */ </font> for testing ('''not''' production).
# Instead of commenting code out for a customer branch, remove it and restore from Version Control if necessary.
# Put your comments in areas that are stored by Oracle, otherwise they are lost after dbPackAndGo:
#* Views: Between the first keyword (''SELECT''/''WITH'') and the closing semicolon
#* Rest: Between the keyword ''AS'' and the final ''END''

=== Files ===
# File name:
#* Header: package_name_h.sql
#* Body: package_name.sql
# Slash (/) at the end of the file
# No SHOW ERROR
# In DDL commands (<font face="Courier">CREATE PACKAGE</font>, <font face="Courier">DROP TABLE</font>, ...) always declare the schema (<font face="Courier">CREATE OR REPLACE PACKAGE '''klassx'''.stock_handler</font>)
# Package / method names are always specified after the <font face="Courier">END</font> statement.

=== Boolean logic ===
# <font face="Courier">IF v_bool THEN</font> instead of <font face="Courier">IF v_bool = TRUE THEN</font>
# <font face="Courier">IF NOT v_bool THEN</font> instead of <font face="Courier">IF v_bool = FALSE THEN</font>
# <font face="Courier">IF SQL%NOTFOUND</font> instead of <font face="Courier">IF NOT SQL%FOUND</font>

== Features ==
=== LISTAGG ===
Aggregation function to concatenate values from multiple rows <small>(replaces STRAGG and STRAGG_DISTINCT which have been removed with One 2.6 since LISTAGG with Oracle 19 has the necessary features)</small>
* Always provide the optional delimiter (default is <source lang="sql" enclose="none">''</source> which is rarely desired)
* Always provide the <source lang="sql" enclose="none">OVERFLOW</source> clause (starting with Oracle 19)

<syntaxhighlight lang="sql">
SELECT LISTAGG( ort.token, ',' ON OVERFLOW TRUNCATE ) WITHIN GROUP( ORDER BY ort.token ) FROM order_type ort;

SELECT LISTAGG( DISTINCT ort.token, ',' ON OVERFLOW ERROR ) WITHIN GROUP( ORDER BY ort.token ) FROM order_type ort;
</syntaxhighlight>

=== DECODE ===
Use ''CASE'' instead.

=== GOTO ===
Do not use.

== SQL ==

=== <div id="alias">Table alias</div> ===
# Always use table aliases in queries unless it equals the table name (<font face="Courier">FROM sku</font> instead of <font face="Courier">FROM sku sku</font>)
# Do not use the same alias for two tables in the same scope (Oracle allows this as long as the columns are unambiguous)
# Use the standard alias defined in internal_db_table.token in queries, this really helps when reading queries.
# When selecting from a view prefix the alias with a <font face="Courier">v</font> followed by the alias according to the rules below. Keep "words" that are already aliases:<br><font face="Courier">v_stock vsto</font><br><font face="Courier">v_pbl_deletable vpbld</font>
# When a more precise table-alias is useful in a query, use the standard alias followed by an underscore (_) and additional info <br><font face="Courier">orl_parent, orp_description</font>.
# Rule to define standard alias for new tables:
#* One word: First three letters <br><font face="Courier">station -> sta</font>
#* Two words: First two letters from the first word and one letter from the second word <br><font face="Courier">order_type -> ort</font>
#* Three or more words: One letter from each word <br>(<font face="Courier">order_event_data_key -> oedk</font>)
#* In case of conflicts try to find a good alternative using additional letters for the table that's less important (or for both to avoid confusion)<br><font face="Courier">order_datamatrix -> orda</font> since it conflicts with <font face="Courier">orders -> ord</font>.

=== Columns ===
# When selecting from more than one table, use table alias for each column.
# Always use the keyword <font face="Courier">AS</font> for column aliases: <font face="Courier">ord_parent.order_id AS parent_order_id</font>
# No column alias if name does not change (<font face="Courier">sku.product_code</font> instead of <font face="Courier">sku.product_code AS product_code</font>)

=== JOIN ===
# Use [[Medium:Ansi-iso-9075-1-1999.pdf|SQL:99]] (ANSI/ISO/IEC 9075:1999, and SQL3) JOIN syntax: <font face="Courier">JOIN tab2 ON …</font> instead of <font face="Courier">FROM tab1, tab2</font>.
# Omit the redundant keywords ''INNER'' and ''OUTER'': <font face="Courier">JOIN order_line orl ON …, LEFT JOIN work_event woe ON …</font>.
# Always put join condition in parentheses: <font face="Courier">ON ( … )</font>.
# The joined table (alias) comes first: <font face="Courier">… JOIN order_line orl ON ( orl.order_id = ord.order_id )</font>.
# Put conditions for properties in the JOIN-statement, not in WHERE<br><font face="Courier">… LEFT JOIN order_property orp_cre_by_user_code ON ( orp_cre_by_user_code.order_id = ord.order_id AND orp_cre_by_user_code.order_property_key_id = lu.opk.created_by_user_code )</font>.
# Start with selecting from the table/view to which the WHERE-clause applies its main filters, join from there<br><font face="Courier">… FROM orders '''ord'''<br>JOIN order_line orl ON ( orl.order_id = ord.order_id )<br>WHERE '''ord'''.order_type_id = lu.ort.classic</font>
# Do not use <source lang="sql" inline>NATURAL JOIN</source>.<br>Hard to understand when queries get more complex and prone to errors when queries or model change.
# Do not use <source lang="sql" inline>JOIN ... USING ( ... )</source>.<br>Needs to be replaced once a <source lang="sql" inline>JOIN</source> with a more complex condition is added.

=== GROUP BY ===
# Avoid large column lists in ''GROUP BY'' if some calculation should be moved to a sub-select instead. This makes the intent clear and avoids having to add to the GROUP BY list whenever a column is added.

; Avoid
<syntaxhighlight lang="sql">
SELECT orl.order_id, orl.line_id, orl.product_bundle_id, orl.reservation_code,
       SUM( ora.quantity ) AS allocated_quantity
  FROM order_line orl
  LEFT JOIN order_allocation ora ON ( ora.order_id = orl.order_id AND ora.line_id = orl.line_id )
 GROUP BY orl.order_id,
          orl.line_id,
          orl.product_bundle_id,
          orl.reservation_code;
</syntaxhighlight>

; Best alternative if only one value is required. Allows optimizer to omit the scalar subquery if the column is not used.
<syntaxhighlight lang="sql">
SELECT orl.order_id, orl.line_id, orl.product_bundle_id, orl.reservation_code,
       ( SELECT SUM( ora.quantity ) FROM order_allocation ora WHERE ( ora.order_id = orl.order_id AND ora.line_id = orl.line_id ) ) AS allocated_quantity
FROM order_line orl;
</syntaxhighlight>

; Alternative if multiple columns are required from the subquery
<syntaxhighlight lang="sql">
SELECT orl.order_id, orl.line_id, orl.product_bundle_id, orl.reservation_code, ora.allocated_quantity
FROM order_line orl
LEFT JOIN
(
    SELECT ora.order_id, ora.line_id, SUM( ora.quantity ) AS allocated_quantity
      FROM order_allocation ora
     GROUP BY ora.order_id, ora.line_id
) ora ON ( ora.order_id = orl.order_id AND ora.line_id = orl.line_id );
</syntaxhighlight>

; Avoid
<syntaxhighlight lang="sql">
SELECT sta.station_id, sta.station_name
  FROM station sta
  JOIN materialflow_strategy mas ON ( mas.stock_area_station_id = sta.station_id )
 GROUP BY sta.station_id, sta.station_name
</syntaxhighlight>

; Better
<syntaxhighlight lang="sql">
SELECT sta.station_id, sta.station_name
  FROM station sta
 WHERE EXISTS ( SELECT 1 FROM materialflow_strategy mas WHERE mas.stock_area_station_id = sta.station_id )
</syntaxhighlight>

=== DISTINCT ===
# Use GROUP BY if possible

=== INSERT ===
# Always specify the list of columns in an INSERT.

; Example
<syntaxhighlight lang="sql">
INSERT INTO my_table( column1, column2 )
    VALUES( 1, 2 );
</syntaxhighlight>

=== Formatting queries ===
Basically it's a question of making the queries as readable as possible.

# Keywords ''SELECT, FROM, JOIN, WHERE, AND, …'' right-aligned under each other.
# Keywords (and '''only''' Keywords ) are uppercase.
#* ''SELECT, DELETE, UPDATE, FROM, JOIN, ON, WHERE, AND, OR, AS, IN, NVL, CASE, …''
#* ''lu.prs.enabled, pbl.product_status_id, …'' are '''not''' Keywords.
# Every ''JOIN'' gets its own row, keyword ''ON'' is on the same row.
#* If JOIN conditions takes up more space than one row, additional text is indented.


=== Performance ===
# JOIN additional tables if possible instead of calling PL/SQL functions in SQL.
#* Example:<br><font face="Courier">SELECT *<br>&nbsp;&nbsp;FROM orders ord<br>&nbsp;&nbsp;JOIN warehouse_shift was ON ( was.shift_id = ord.shift_id )<br>&nbsp;WHERE was.shift_status_id = lu.shs.new;</font><br>Not:<br><strike><font face="Courier"> SELECT *<br>&nbsp;&nbsp;FROM orders ord<br>&nbsp;WHERE shift_handler.get_shift_status( ord.shift_id ) = lu.shs.new;</font></strike><br>
# Use <font face="Courier">CARDINALITY</font> hint when selecting from PL/SQL tables.
#* The exact number is not that important, but if we do not provide the hint the optimizer always assumes ''8168'' rows.
#*<font face="Courier">… WHERE order_id IN ( SELECT /*+ CARDINALITY( tab 10 ) */ FROM TABLE( in_order_ids ) tab )</font>
# Use <font face="Courier">RETURNING</font> clause instead of performing another <font face="Courier">SELECT</font> where possible.

=== Consistency ===
# Avoid inconsistencies and deadlocks<br>Make sure that other sessions wait for the correct locks<br>Make code deterministic
## When modifying multiple rows of the same table in a LOOP, use ''ORDER BY'' (usually by the primary key)
## When modifying rows in multiple tables in one transaction, always start with parent where possible (''orders'' before ''order_line'', ''sku'' before ''product_bundle'', …).
##* If the parent is not updated, but the state of the parent or of a child is relevant for the logic, think about locking the parent row(s) by using ''SELECT ... FOR UPDATE OF <alias>.<first pk column>''.<br>[[Bild:Symbol Verantwortung.png | Attention]] The query returns consistent data, so if our query relies on data of '''other''' tables that might have changed while we waited for the row lock, we still get the old information. In that case the ''FOR UPDATE'' needs to be in a separate query before gathering other data.
##* If tables are not related, try to use the same update sequence everywhere

=== Example ===
<syntaxhighlight lang="sql">
SELECT loc.location_id, loc.station_id, loc.location_code,
       ov.get_station_id, ov.get_product_bundle_id, ov.get_aggregation_station_id, ov.put_aggregation_station_id,
       pbl.product_bundle_location_id, pbl.max_location_quantity,
       prb.product_bundle_id, prb.bundle_size, sku.product_code, sku.product_name,
       ord_repl.order_id AS replenishment_order_id,
       GREATEST( 1, NVL( pbl.max_location_quantity, 0 ) - NVL( pbl.act_location_quantity, 0 ) ) AS channel_requested_quantity,
       CASE WHEN EXISTS
       (
           SELECT 1
             FROM location loc_ov
             JOIN loading_unit lou_ov ON ( lou_ov.location_id = loc_ov.location_id )
             JOIN stock sto_ov ON ( sto_ov.loading_unit_id = lou_ov.loading_unit_id )
             JOIN product_bundle prb_ov ON ( prb_ov.product_bundle_id = sto_ov.product_bundle_id )
            WHERE prb_ov.sku_id = sku.sku_id  -- match sku instead of bundle, replenishment could detrash bigger bundles
              AND sto_ov.deleted = util_bool.no
              AND loc_ov.station_id = ov.get_station_id -- check station, there might be more than one overstock location
              AND lou_ov.deleted = util_bool.no
       )
         THEN util_bool.yes
         ELSE util_bool.no
       END AS lok_available_at_overstock
  FROM product_bundle_location pbl
  JOIN product_bundle prb ON ( prb.product_bundle_id = pbl.product_bundle_id AND prb.product_status_id = lu.prs.active )
  JOIN sku ON ( sku.sku_id = prb.sku_id AND sku.product_status_id = lu.prs.active )
  JOIN location loc ON ( loc.location_id = pbl.location_id )
  -- there could be several channels of a parallel group, or the primary channel could be missing from the list
  JOIN
  (
      SELECT pbl_par.product_bundle_id, loc_par.station_id
        FROM product_bundle_location pbl_par
        JOIN location loc_par ON ( loc_par.location_id = pbl_par.location_id )
       WHERE pbl_par.product_bundle_location_id IN ( SELECT /*+ CARDINALITY( tab 1 ) */ COLUMN_VALUE FROM TABLE( in_product_bundle_location_ids ) tab )
         -- the channels of a parallel group have to meet the following conditions too.
         AND pbl_par.block_replenishment = util_bool.no
         AND pbl_par.freeze_replenishment = util_bool.no
         AND pbl_par.product_status_id = lu.prs.active
       GROUP BY pbl_par.product_bundle_id, loc_par.station_id
  ) par_grp ON ( par_grp.product_bundle_id = pbl.product_bundle_id AND par_grp.station_id = loc.station_id )
  LEFT JOIN
  (
      -- Make sure that matching product_bundle_location exists, but only return first row in case there are multiple overstock locations
      SELECT prb_get.sku_id, prb_get.product_bundle_id AS get_product_bundle_id,
             loc_get.station_id AS get_station_id,
             stp_get.aggregation_station_id AS get_aggregation_station_id,
             stp_put.station_id AS put_station_id,
             stp_put.aggregation_station_id AS put_aggregation_station_id,
             ROW_NUMBER() OVER ( PARTITION BY stp_put.station_id, prb_get.sku_id ORDER BY pbl_get.product_bundle_location_id ) AS rn
        FROM station_parameter stp_put
        JOIN materialflow_path map ON ( map.target_stock_area_station_id = stp_put.stock_area_station_id )
        JOIN station_parameter stp_get ON ( stp_get.stock_area_station_id = map.source_stock_area_station_id )
        JOIN location loc_get ON ( loc_get.station_id = stp_get.station_id AND loc_get.deleted = util_bool.no )
        JOIN product_bundle_location pbl_get ON (     pbl_get.location_id = loc_get.location_id
                                                  AND pbl_get.product_status_id = lu.prs.active )
        JOIN product_bundle prb_get ON ( prb_get.product_bundle_id = pbl_get.product_bundle_id )
  ) ov ON ( ov.put_station_id = loc.station_id AND ov.sku_id = prb.sku_id AND rn = 1 )
  LEFT JOIN orders ord_repl ON ( ord_repl.order_id = pbl.replenishment_order_id AND ord_repl.process_status_id < lu.ops.finished )
 WHERE pbl.block_replenishment = util_bool.no
   AND pbl.freeze_replenishment = util_bool.no
   AND pbl.product_status_id = lu.prs.active
 ORDER BY loc.station_id,                 -- sort groups of parallel channels (station_id, product_bundle_id)
          pbl.product_bundle_id,
          loc.location_code,
          pbl.product_bundle_location_id  -- sort channels within groups of parallel channels
</syntaxhighlight>
