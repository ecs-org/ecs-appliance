local br_change sys_change ds_change pip_change mig_change mig_add
if $init_all; then
    # init_all does not need dump restore => mig_change=1
    echo "init_all: marking everything as changed (except mig_change)"
    br_change=true; sys_change=true; ds_change=true; pip_change=true
    mig_change=false; mig_add=true
else
    echo "collect differences"
    br_change=$(test "$current_branch" != "$target_branch" && echo true || echo false)
    sys_change=$(git diff --name-status HEAD..origin/$target_branch | \
        grep -q  "requirements/system.apt" && echo true || echo false)
    ds_change=$(git diff --name-status HEAD..origin/$target_branch | \
        grep -q "conf/devserver" && echo true || echo false)
    pip_change=$(git diff --name-status HEAD..origin/$target_branch | \
        grep -q "requirements/all.freeze" && echo true || echo false)
    mig_change=$(git diff --name-status HEAD..origin/$target_branch | \
        grep -q "^[^A].*/migrations/" && echo true || echo false)
    mig_add=$(git diff --name-status HEAD..origin/$target_branch | \
        grep -q "^A.*/migrations/" && echo true || echo false)
    echo "changed: br: $br_change, sys: $sys_change, ds: $ds_change, pip: $pip_change, migC: $mig_change, migA: $mig_add"

    echo "reset workdir to origin/$target_branch"
    git checkout -f $target_branch
    git reset --hard origin/$target_branch
fi
