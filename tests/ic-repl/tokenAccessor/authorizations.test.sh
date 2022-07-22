#!/usr/local/bin/ic-repl

load "../common/install.sh";

identity alice;
identity bob;
identity default;

// Create the token accessor
let token_accessor = installTokenAccessor(default);

call token_accessor.getToken();
assert _ == (null : opt record{});
call token_accessor.getAdmin();
assert _ == default;
call token_accessor.getMinters();
assert _ == vec{default;};
call token_accessor.getMintRegister();
assert _ == vec{};

// Alice tries to add herself as minter, it shall fail
identity alice;
call token_accessor.addMinter(alice);
assert _ == variant { err = variant { NotAuthorized } };
call token_accessor.isAuthorizedMinter(alice);
assert _ == false;
call token_accessor.getMinters();
assert _ == vec{default;};

// Bob is added as minter by the current admin, it shall succeed
identity default;
call token_accessor.addMinter(bob);
assert _ == variant { ok };
call token_accessor.isAuthorizedMinter(bob);
assert _ == true;
call token_accessor.getMinters();
assert _ == vec{default; bob;};

// Bob tries to add Alice as minter, it fails cause only admin can do it
identity bob;
call token_accessor.addMinter(alice);
assert _ == variant { err = variant { NotAuthorized } };
call token_accessor.isAuthorizedMinter(alice);
assert _ == false;
call token_accessor.getMinters();
assert _ == vec{default; bob;};

// Bob tries to put himself as admin, it shall fail, only the admin can do that
identity bob;
call token_accessor.setAdmin(bob);
assert _ == variant { err = variant { NotAuthorized } };
call token_accessor.getAdmin();
assert _ == default;

// The current admin finally puts bob as admin, it shall succeed 
// and the current admin shall be removed from the list of authorized minters
identity default;
call token_accessor.setAdmin(bob);
assert _ == variant { ok };
call token_accessor.getAdmin();
assert _ == bob;
call token_accessor.isAuthorizedMinter(default);
assert _ == false;
call token_accessor.getMinters();
assert _ == vec{bob;};

// Bob shall now be allowed to add Alice as minter
identity bob;
call token_accessor.addMinter(alice);
assert _ == variant { ok };
call token_accessor.isAuthorizedMinter(alice);
assert _ == true;
call token_accessor.getMinters();
assert _ == vec{bob; alice;};