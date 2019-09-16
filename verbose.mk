# Verbosity
AT_ = @
AT = $(AT_$(V))
_redirect_ := 1>/dev/null
_redirect_1 :=
redirect = $(_redirect_$(V))
# /Verbosity
