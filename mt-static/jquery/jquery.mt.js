/*
 * Movable Type (r) Open Source (C) 2001-2009 Six Apart, Ltd.
 * This program is distributed under the terms of the
 * GNU General Public License, version 2.
 *
 * $Id$
 */
;(function($) {

/*
 * mtAddEdgeClass
 *
 * Usage:
 *   jQuery.mtAddEdgeClass()
 *
 */
$.mtAddEdgeClass = function() {
    $('body *')
        .filter(':first-child').addClass('first-child')
        .end()
        .filter(':last-child').addClass('last-child');
};

/*
 * mtMenu
 *
 * Usage:
 *   jQuery.mtMenu();
 *
 */
$.mtMenu = function(options) {
    var defaults = {
        position: 'left'
    };
    var opts = $.extend(defaults, options);
    $('#menu').css('float', opts.position);
    $('#content').css('float', opts.position);
    $('#content').css('margine-left', '0px');
    $('#content').css('margine-right', '0px');
    $('#content').css('margine-'+opts.position, '-150px');

    $('.top-menu > a').after('<span class="toggle-button"></span>');
    $('.top-menu .toggle-button').click(function() {
        $(this).parent('li').toggleClass('top-menu-open');
        $(this).next().toggle();
    });
};


/*
 * mtSelector
 *
 * Usage:
 *   jQuery.mtSelector();
 *
 */
$.mtSelector = function() {
    $('#system-overview > em').prepend('<span class="toggle-button"></span>');
    $('#user-dashboard > em').prepend('<span class="toggle-button"></span>');
    $('#current-website > em').prepend('<span class="toggle-button"></span>');

    $('#selector-nav li span').click(function() {
        $(this).parent('em').parents('#selector-nav').toggleClass('show-selector');
    });
    $(document).click(function(event) {
        if ($(event.target).parents('#selector-nav').length == 0) {
            $('#selector-nav li span').parent('em').parents('#selector-nav').removeClass('show-selector');
        }
    });
};

/*
 * mtCheckbox
 *
 * Usage:
 *   jQuery.mtCheckbox();
 *
 */
$.mtCheckbox = function() {
    $('thead :checkbox, tfoot :checkbox').click(function() {
        var $checkboxes = $(this).parents('table').find(':checkbox');
        if (this.checked) {
            $checkboxes.parents('tr').addClass('selected');
            $checkboxes.attr('checked', true);
        } else {
            $checkboxes.parents('tr').removeClass('selected');
            $checkboxes.removeAttr('checked');
        }
    });
    $('tbody :checkbox').click(function() {
       var n = $('tbody input:checked').length;
       if ($('tbody :checkbox').length === n) {
           $('thead :checkbox, tfoot :checkbox').attr('checked', true);
       } else {
           $('thead :checkbox, tfoot :checkbox').removeAttr('checked');
       }
    });
};

/*
 * mtQuickFilter
 *
 * Usage:
 *   jQuery.mtQuickFilter()
 *
 */
$.mtQuickFilter = function() {
    $('form#list-filter button').hide();
    $('select.filter-keys').change(function() {
        $('form#list-filter').submit();
    });
};

/*
 * mtDisplayOptions
 *
 * Usage:
 *   jQuery.mtDisplayOptions();
 *
 */
$.mtDisplayOptions = function() {
    $('div#display-options-widget').css('position', 'absolute').hide();
    // for ie6 tweaks
    if (!$.support.style && !$.support.objectAll) {
        if ($.fn.bgiframe) $('div#display-options-widget').bgiframe();
    }

    $('a.display-options-link').click(function() {
        $('a.display-options-link').toggleClass('display-options-link-open');
        $('div#display-options-widget').toggle();
        return false;
    });

    $('button.close-display-options').click(function(event) {
        $('a.display-options-link').removeClass('display-options-link-open');
        $('div#display-options-widget').hide();
        return false;
    });

    $(document).click(function(event) {
        if ($(event.target).parents('#display-options-widget').length == 0) {
            $('a.display-options-link').removeClass('display-options-link-open');
            $('div#display-options-widget').hide();
        }
    });
};

/*
 * mtDialog
 *
 * Usage:
 *   jQuery('a.mt-open-dialog').mtDialog();
 *
 *   <a href="mt.cgi" class="mt-open-dialog">Dialog</a>
 *
 * to use dialog directly:
 *   jQuery.fn.mtDialog.open(url);
 *
 * to close dialog from iframe:
 *   parent.jQuery.fn.mtDialog.close();
 *
 * to set close callback:
 *   parent.jQuery.fn.mtDialog.close(url, function(e) {
 *     parent.jQuery('#title').val('MT5');
 *   });
 *
 */
$.fn.mtDialog = function(options) {
    var defaults = {
        loadingimage: StaticURI+'images/indicator.gif',
        esckeyclose: true
    };
    var opts = $.extend(defaults, options);
    init_dialog();
    return this.each(function() {
        $(this).click(function() {
            open_dialog(this.href, opts);
            return false;
        });
    });
};

function init_dialog() {
    $(window).resize(function() {
        resize_dialog();
    });
    var $dialog = $('.mt-dialog');
    if (!$dialog.length) {
        $('body').append('<div class="mt-dialog"><div><span>Close</a></div></span>');
        $('.mt-dialog').after('<div class="mt-dialog-overlay"></div>');
        $(".mt-dialog > div > span").click(function() {
            close_dialog();
        });
    }
};

function resize_dialog() {
    var $dialog = $('.mt-dialog');
    var height = $(window).height();
    if ($dialog.length) {
        $dialog.height(height - 60);
        $('#mt-dialog-iframe').height(height - 60);
    }
};

function open_dialog(href, opts) {
    if ( opts.form ) {
        var param = opts.param;
        $('<iframe />')
            .attr({
                id: 'mt-dialog-iframe',
                name: 'mt-dialog-iframe',
                frameborder: '0',
                width: '100%'
            })
            .load(function() {
                $('.mt-dialog .loading').remove();
            })
            .appendTo($('.mt-dialog'));
        resize_dialog();
        $('<img />')
            .attr({
                src: opts.loadingimage
            })
            .addClass('loading')
            .appendTo($('.mt-dialog'));
        var form = $('<form />')
            .attr({
                'id': 'mt-dialog-post-form',
                'method': 'post',
                'action': href,
                'target': 'mt-dialog-iframe'
            })
            .append( $( '#' + opts.form).children().clone() )
            .appendTo($('.mt-dialog'));
        $.each( param, function( key, val ) {
            form.find('[name=' + key + ']').remove();
            $('<input />')
                .attr({
                    'type': 'hidden',
                    'name': key,
                    'value': val
                })
                .appendTo( form )
        });
        form.submit();
        form.remove();
    }
    else {
        $('<iframe />')
            .attr({
                id: 'mt-dialog-iframe',
                frameborder: '0',
                src: href+'&dialog=1',
                width: '100%'
            })
            .load(function() {
                $('.mt-dialog .loading').remove();
            })
            .appendTo($('.mt-dialog'));
        resize_dialog();
        $('<img />')
            .attr({
                src: opts.loadingimage
            })
            .addClass('loading')
            .appendTo($('.mt-dialog'));
    }
    $('body').css('overflow', 'hidden');
    $('.mt-dialog').show();
    $('.mt-dialog').bind('close', function(event, fn) {
        fn(event);
    });
    $('.mt-dialog-overlay').show();
    if (opts.esckeyclose) {
        $(document).keyup(function(event){
            if (event.keyCode == 27) {
                close_dialog();
            }
        });
    }
    // for ie6 tweaks
    if (!$.support.style && !$.support.objectAll) {
        if ($.fn.bgiframe) $('.mt-dialog-overlay').bgiframe();
        if ($.fn.exFixed) $('.mt-dialog').exFixed();
    }
};

function close_dialog(url, fn) {
    $('body').css('overflow', '');
    $('.mt-dialog-overlay').hide();
    if (fn) {
        $('.mt-dialog').trigger('close', fn);
    }
    $('.mt-dialog').unbind('close');
    $('.mt-dialog').hide();
    $('#mt-dialog-iframe').remove();
    if (url) {
        window.location = url;
    }
};

$.fn.mtDialog.open = function(url, options) {
    var defaults = {
        loadingimage: StaticURI+'images/indicator.gif',
        esckeyclose: true
    };
    var opts = $.extend(defaults, options);
    init_dialog();
    open_dialog(url, opts);
};

$.fn.mtDialog.close = function(url, fn) {
    close_dialog(url, fn);
};

/*
 * mtRebuild
 *
 * Usage:
 *   jQuery('a.mt-rebuild').mtRebuild({blog_id: 1});
 *
 *   <a href="mt.cgi" class="mt-rebuild">Rebuild</a>
 *
 */
$.fn.mtRebuild = function(options) {
    var defaults = {};
    var opts = $.extend(defaults, options);
    $(this).click(function() {
        window.open($(this).attr('href'), 'rebuild_blog_'+opts.blog_id, 'width=400,height=400,resizable=yes');
        return false;
    });
};

/*
 * mtSetTip
 *
 * Usage:
 *   jQuery(':input').mtSetTip();
 *
 *   <input title="sample text" />
 *
 */
$.fn.mtSetTip = function(options) {
    var defaults = {
        tip_color: '#aaaaaa'
    };
    var opts = $.extend(defaults, options);
    return this.each(function() {
        var text = $(this).attr('title');
        $(this).val(text).css('color', opts.tip_color);
        $(this).focus(function() {
            if (this.value == text) {
                $(this).val('').css('color', '#000');
            }
        });
        $(this).blur(function() {
            if ($(this).val() == '') {
                $(this).val(text).css('color', opts.tip_color);
            }
            if (this.value != text) {
                $(this).css('color', '#000');
            }
        });
    });
};

/*
 * mtPublishItems
 *
 */
$.fn.mtPublishItems = function(options) {
    var defaults = {
        name: null,
        args: {}
    };
    var opts = $.extend(defaults, options);
    return this.each(function() {
        $(this).click(function() {
            doForMarkedInThisWindow($('#'+opts.id)[0], opts.singular, opts.plural, opts.name, opts.mode, opts.args, opts.phrase);
            return false;
        });
    });
};

/*
 * mtSubmitItems
 *
 */
$.fn.mtSubmitItems = function(options) {
    var defaults = {};
    var opts = $.extend(defaults, options);
    return this.each(function() {
        $(this).click(function() {
            $('form#'+opts.id+' > input[name=__mode]').val('save_entries');
        });
    });
};

/*
 * mtDeleteItems
 *
 */
$.fn.mtDeleteItems = function(options) {
    var defaults = {};
    var opts = $.extend(defaults, options);
    return this.each(function() {
        $(this).click(function() {
            doRemoveItems($('#'+opts.id)[0], opts.singular, opts.plural);
            return false;
        });
    });
};

/*
 * mtEnableUsers
 *
 */
$.fn.mtEnableUsers = function(options) {
    var defaults = {};
    var opts = $.extend(defaults, options);
    return this.each(function() {
        $(this).click(function() {
            setObjectStatus($('#'+opts.id)[0], opts.plural, opts.phrase, 1);
            return false;
        });
    });
};

/*
 * mtDisableUsers
 *
 */
$.fn.mtDisableUsers = function(options) {
    var defaults = {};
    var opts = $.extend(defaults, options);
    return this.each(function() {
        $(this).click(function() {
            var sysadmin = $('#sysadmin')[0];
            if (sysadmin && sysadmin.checked) {
                alert(opts.message);
                sysadmin.click();
                return false;
            }
            setObjectStatus($('#'+opts.id)[0], opts.plural, opts.phrase, 0);
            return false;
        });
    });
};

/*
 * mtDoPluginAction
 *
 */
$.fn.mtDoPluginAction = function(options) {
    var defaults = {};
    var opts = $.extend(defaults, options);
    return this.each(function() {
        $(this).click(function() {
            doPluginAction($('#'+opts.id)[0], opts.plural, opts.phrase);
            return false;
        });
    });
};

/*
 * mtRebasename
 *
 */
$.fn.mtRebasename = function(options) {
    var defaults = {
        text: '...'
    };
    var opts = $.extend(defaults, options);
    return this.each(function() {
        var $input = $('input#basename');
        var dirify_text = $input.hide().val();
        if (opts.basename) {
            $('span.basename-text').text(opts.basename);
        } else {
            $input
                .before('<span class="basename-text"></span>')
                .after('<button id="mt-set-basename" class="mt-edit-field-button">'+opts.edit+'</button>')
                .hide();
            $('span.basename-text').text(dirify_text || opts.text);
        }
        $(this).keyup(function() {
            if (!opts.basename) {
                dirify_text = dirify($(this).val());
                $('span.basename-text').text(dirify_text || opts.text);
                $input.val(dirify_text);
            }
        });
    });
};

/*
 * mtEditInput
 *
 * Usage:
 *   jQuery('input.mt-edit-field').mtEditInput({ edit: '<__trans phrase="Edit">'});
 *
 *   <input name="test" class="mt-edit-field" />
 *
 */
$.fn.mtEditInput = function(options) {
    var defaults = {
        save: 'Save'
    };
    var opts = $.extend(defaults, options);
    return this.each(function() {
        var id = $(this).attr('id');
        var $input = $('input#'+id);
        if ($input.val()) {
            $input
                .before('<span class="'+id+'-text"></span>')
                .after('<button id="mt-set-'+id+'" class="mt-edit-field-button">'+opts.edit+'</button>')
                .hide();
            $('span.'+id+'-text').text($input.val());
        }
        $('button#mt-set-'+id).click(function() {
            $(this).hide();
            $('span.'+id+'-text').hide();
            $('input#'+id).show();
            $('p#'+id+'-warning').show();
            return false;
        });
    });
};

/*
 * mtCheckboxOption
 *
 * Usage:
 *   jQuery.mtCheckbox();
 *
 */
$.fn.mtCheckboxOption = function() {
    return this.each(function() {
        var $checkbox = $(this).find(':checkbox');
        var id = $checkbox.attr('id');
        if (!$checkbox.attr('checked')) {
            $('div#'+id+'-option').hide();
        }
        $checkbox.click(function() {
            $('div#'+id+'-option').toggle();
        });
    });
};

})(jQuery);