/*
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
initial if ($test$plusargs("DUMP")) begin
    $dumpfile("dump.vcd");
    $dumpvars(); 
end
