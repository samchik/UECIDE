package org.uecide.builtin;

import org.uecide.*;

public class push implements BuiltinCommand {
    public boolean main(Context ctx, String[] arg) {
        if (arg.length != 2) {
            ctx.error("Usage: __builtin_push::variable::value");
            return false;
        }

        String val = null;
        val = ctx.get(arg[0]);
        if (val == null) {
            val = "";
        }

        if (!val.equals("")) {
            val += "::";
        }

        val += arg[1];

        ctx.set(arg[0], val);
        return true;
    }
}
