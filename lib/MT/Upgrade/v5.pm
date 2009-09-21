# Movable Type (r) Open Source (C) 2001-2008 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id$

package MT::Upgrade::v5;

use strict;

sub upgrade_functions {
    return {
        #'v5_migrate_blog' => {
        #    version_limit => 5.0004,
        #    priority      => 3.2,
        #    code          => \&_v5_migrate_blog,
        #},
        'v5_create_new_role' => {
            version_limit => 5.0010,
            priority      => 3.1,
            code          => \&_v5_create_new_role,
        },
        'v5_migrate_system_privilege' => {
            version_limit => 5.0004,
            priority      => 3.1,
            code          => \&_v5_migrate_system_privilege,
        },
        'v5_migrate_theme_privilege' => {
            version_limit => 5.0014,
            priority      => 3.1,
            code          => \&_v5_migrate_theme_privilege,
        },
        'v5_migrate_mtview' => {
            version_limit => 5.0004,
            priority      => 3.1,
            code          => \&_v5_migrate_mtview,
        },
        'v5_migrate_default_site' => {
            version_limit => 5.0008,
            priority      => 3.3,
            code          => \&_v5_migrate_default_site
        },
        'v5_migrate_dashboard_widget_settings' => {
            version_limit => 5.0013,
            priority      => 3.3,
            updater => {
                type => 'author',
                label => "Merging dashboard settings...",
                condition => sub { $_[0]->status(1) && $_[0]->type(1) },
                code          => \&_v5_migrate_dashboard,
            },
        },
        'v5_migrate_blog_only' => {
            version_limit => 5.0014,
            priority      => 3.2,
            updater => {
                type      => 'blog',
                label     => "Classifying blogs...",
                condition => sub { !$_[0]->class },
                code      => sub { $_[0]->class('blog') },
                sql       => "update mt_blog set blog_class='blog'
                              where ( blog_class IS NULL ) or ( blog_class = '' )
                              or ( blog_class = '0' )",
            },
        },
        'v5_generate_websites_place_blogs' => {
            version_limit => 5.0014,
            priority      => 3.4,
            code          => \&_v5_generate_websites_place_blogs,
        },
    };
}

### Subroutines

sub _v5_migrate_blog {
    my $self = shift;

    my $app = $MT::Upgrade::App;
    my $user = MT::Author->load( $app->{author}->id );
    return if $user->permissions(0)->has('administer_website');

    # Create generic website.
    my $class = MT->model('website');
    return $self->error($self->translate_escape("Error loading class: [_1].", 'Website'))
        unless $class;

    return if $class->count() > 0;

    $self->progress($self->translate_escape('Populating generic website for current blogs...'));

    my $website = $class->create_default_website(MT->translate('Generic Website'));
    $website->site_path('');
    $website->site_url('');
    $website->save
        or return $self->error($self->translate_escape("Error saving record: [_1].", $website->errstr));

    # Load all blogs.
    my $blog_class = MT->model('blog');
    return $self->error($self->translate_escape("Error loading class: [_1].", 'Blog'))
        unless $blog_class;
    my $iter = $blog_class->load_iter();
    while(my $blog = $iter->()){
        next if $blog->parent_id;
        $self->progress($self->translate_escape("Migrating [_1]([_2]).", $blog->name, $blog->id));
        $blog->class('blog');
        $blog->parent_id($website->id);
        $blog->save
            or return $self->error($self->translate_escape("Error saving record: [_1].", $blog->errstr));
    }

    # Grant new role to system administrator
    $self->progress($self->translate_escape('Granting new role to system administrator...'));

    my $assoc_class = MT->model('association');
    return $self->error($self->translate_escape("Error loading class: [_1].", 'Association'))
        unless $assoc_class;
    my $role_class = MT->model('role');
    return $self->error($self->translate_escape("Error loading class: [_1].", 'Role'))
        unless $role_class;
    my $role = MT::Role->load_by_permission('administer_website');
    $assoc_class->link( $user => $role => $website );

    return;
}

sub _v5_create_new_role {
    my $self = shift;

    my $role_class = MT->model('role');
    return $self->error($self->translate_escape("Error loading class: [_1].", 'Role'))
        unless $role_class;

    $self->progress($self->translate_escape('Updating existing role name...'));
    my $role = $role_class->load({
        name => MT->translate('_WEBMASTER_MT4'),
    });
    if ( $role ) {
        $role->name( MT->translate('Webmaster (MT4)') );
        $role->save
            or return $self->error($self->translate_escape("Error saving record: [_1].", $role->errstr));
    }

    $self->progress($self->translate_escape('Populating new role for website...'));
    $role = $role_class->load({
        name => MT->translate('Website Administrator'),
    });
    if (!$role) {
        $role = $role_class->new();
        $role->name(MT->translate('Website Administrator'));
        $role->description(MT->translate('Can administer the website.'));
        $role->clear_full_permissions;
        $role->set_these_permissions(['administer_website', 'manage_member_blogs']);
        $role->save
            or return $self->error($self->translate_escape("Error saving record: [_1].", $role->errstr));
    }

    my $new_role = $role_class->new();
    $new_role->name(MT->translate('Webmaster'));
    $new_role->description(MT->translate('Can manage pages, Upload files and publish blog templates.'));
    $new_role->clear_full_permissions;
    $new_role->set_these_permissions(['manage_pages', 'rebuild', 'upload']);
    $new_role->save
        or return $self->error($self->translate_escape("Error saving record: [_1].", $new_role->errstr));
}

sub _v5_migrate_theme_privilege {
    my $self = shift;

    my $role_class = MT->model('role');
    return $self->error($self->translate_escape("Error loading class: [_1].", 'Role'))
        unless $role_class;

    $self->progress($self->translate_escape('Updating existing role name...'));
    my $role = $role_class->load({
        name => MT->translate('Designer'),
    });
    if ( $role ) {
        $role->name( MT->translate('Designer (MT4)') );
        $role->save
            or return $self->error($self->translate_escape("Error saving record: [_1].", $role->errstr));
    }

    $self->progress($self->translate_escape('Populating new role for theme...'));
    my $new_role = $role_class->new();
    $new_role->name(MT->translate('Designer'));
    $new_role->description(MT->translate('Can edit, manage and publish blog templates and themes.'));
    $new_role->clear_full_permissions;
    $new_role->set_these_permissions(['manage_themes', 'edit_templates', 'rebuild']);
    $new_role->save
        or return $self->error($self->translate_escape("Error saving record: [_1].", $new_role->errstr));
}

sub _v5_migrate_system_privilege {
    my $self = shift;
    $self->progress($self->translate_escape('Assigning new system privilege for system administrator...'));

    my $perm_class = MT->model('permission');
    return $self->error($self->translate_escape("Error loading class: [_1].", 'Permission'))
        unless $perm_class;
    my $iter = $perm_class->load_iter({
        blog_id => 0,
    });
    while(my $perm = $iter->()) {
        if ($perm->has('administer')) {
            $self->progress($self->translate_escape('Assigning to  [_1]...', $perm->author->name));
            $perm->set_these_permissions(['create_website']);
            $perm->save
                or return $self->error($self->translate_escape("Error saving record: [_1].", $perm->errstr));
        }
    }
}

sub _v5_migrate_mtview {
    my $self = shift;

    $self->progress($self->translate_escape('Migrating mtview.php to MT5 style...'));

    require MT::FileMgr;
    my $fmgr = MT::FileMgr->new('Local');

    my $blog_class = MT->model('blog');
    return $self->error($self->translate_escape("Error loading class: [_1].", 'Website'))
        unless $blog_class;

    require File::Spec;
    my $iter = $blog_class->load_iter({ class => 'blog' });
    while (my $blog = $iter->()) {
        my $site_path = $blog->site_path;
        my $mtview = File::Spec->catfile($site_path, 'mtview.php');
        if ($fmgr->exists($mtview)) {
            my $data = $fmgr->get_data($mtview);
            if ($data) {
                $data =~ s/new MT/MT::get_instance/;
                $fmgr->rename($mtview, $mtview.'.bak');
                $fmgr->put_data($data, $mtview);
            }
        }
    }
}

sub _v5_migrate_default_site {
    my $self = shift;


    my $site_url = MT->config('DefaultSiteURL');
    my $site_path = MT->config('DefaultSiteRoot');

    if ( $site_url && $site_path ) {
        $self->progress($self->translate_escape('Migrating DefaultSiteURL/DefaultSiteRoot to website...'));

        my $class = MT->model('website');
        return $self->error($self->translate_escape("Error loading class: [_1].", 'Website'))
            unless $class;

        my $website = $class->create_default_website(MT->translate('Website for new User'));
        $website->site_path($site_path);
        $website->site_url($site_url);
        $website->save
            or return $self->error($self->translate_escape("Error saving record: [_1].", $website->errstr));

        MT->config('NewUserDefaultWebsiteId', $website->id, 1);
        MT->config('DefaultSiteURL', undef, 1);
        MT->config('DefaultSiteRoot', undef, 1);

        # Grant new role to system administrator
        my $app = $MT::Upgrade::App;
        my $user = MT::Author->load( $app->{author}->id );
        my $assoc_class = MT->model('association');
        return $self->error($self->translate_escape("Error loading class: [_1].", 'Association'))
            unless $assoc_class;
        my $role_class = MT->model('role');
        return $self->error($self->translate_escape("Error loading class: [_1].", 'Role'))
            unless $role_class;
        my $role = MT::Role->load_by_permission('administer_website');
        $assoc_class->link( $user => $role => $website );
    }
}

sub _v5_migrate_dashboard {
    my $user = shift;
    my $conf = $user->widgets;
    return 1 unless $conf;

    my $new_widgets;
    my @keys = keys %$conf;
    foreach my $key ( @keys ) {
        my @widget_keys = keys %{ $conf->{$key} };
        foreach my $widget ( @widget_keys ) {
            if ( $widget eq 'mt_shortcuts' ) {
                next;
            } elsif ( $widget eq 'this_is_you-1' || $widget eq 'new_install' || $widget eq 'new_user' ) {
                $new_widgets->{'dashboard:user:'.$user->id}->{$widget}->{order} = $conf->{$key}->{$widget}->{order};
                $new_widgets->{'dashboard:user:'.$user->id}->{$widget}->{set} = 'main';
                next;
            } elsif ( $widget eq 'mt_news' ) {
                $new_widgets->{'dashboard:user:'.$user->id}->{$widget}->{order} = $conf->{$key}->{$widget}->{order};
                $new_widgets->{'dashboard:user:'.$user->id}->{$widget}->{set} = 'sidebar';
                next;
            } elsif ( $widget eq 'blog_stats' && $key eq 'dashboard:system' ) {
                next;
            }
            $new_widgets->{$key}->{$widget} = $conf->{$key}->{$widget};
        }
    }

    # New widgets from MT5
    $new_widgets->{'dashboard:user:'.$user->id}->{'favorite_blogs'}->{order} = 3;
    $new_widgets->{'dashboard:user:'.$user->id}->{'favorite_blogs'}->{set} = 'main';
    $new_widgets->{'dashboard:system'}->{'recent_websites'}->{order} = 1;
    $new_widgets->{'dashboard:system'}->{'recent_websites'}->{set} = 'main';

    my $class = MT->model('website');
    return unless $class;
    my $generic_website = $class->load({
        name => MT->translate('Generic Website')
    });
    return unless $generic_website;

    $new_widgets->{'dashboard:blog:'.$generic_website->id}->{'recent_blogs'}->{order} = 1;
    $new_widgets->{'dashboard:blog:'.$generic_website->id}->{'recent_blogs'}->{set} = 'main';

    $user->widgets( $new_widgets );
    $user->save;
}

sub _v5_generate_websites_place_blogs {
    my $self = shift;

    require MT::Blog;
    my $iter = MT::Blog->load_iter( [
        { class => 'blog' },
        '-and',
        [
            { parent_id => \'IS NULL' }, '-or', { parent_id => '' }
        ]
    ] );

    my %site_urls;
    while ( my $blog = $iter->() ) {
        $site_urls{ $blog->site_url } = $blog;
    }

    return unless %site_urls;

    $self->progress($self->translate_escape('Migrating existing [quant,_1,blog,blogs] into websites and its children...', scalar(keys(%site_urls))));

    my $assoc_class = MT->model('association');
    return $self->error($self->translate_escape("Error loading class: [_1].", 'Association'))
        unless $assoc_class;
    my $role_class = MT->model('role');
    return $self->error($self->translate_escape("Error loading class: [_1].", 'Role'))
        unless $role_class;
    my $role = $role_class->load_by_permission('administer_website');
    return $self->error($self->translate_escape("Error loading role: [_1].", 'administer_website'))
        unless $role;

    my @sysadmins = MT::Author->load(
        {
            type => MT::Author::AUTHOR()
        },
        {
            join => MT::Permission->join_on(
                'author_id',
                {
                    permissions => "\%'administer'\%",
                    blog_id     => '0',
                },
                { 'like' => { 'permissions' => 1 } }
            )
        }
    );

    # 1. find the shortest site_url, pick its domain and make it as a website url
    # 2. find urls under the domain and make it children
    # 3. find urls of that are subdomains of the domain and make it children
    # 4. go to step 1 until everything is either a child or a website

    my $website_class= MT->model('website');
    my %websites;
    while ( my @site_urls = keys %site_urls ) {
        @site_urls = sort { length( $a ) <=> length ( $b ) } @site_urls;
        my $shortest = shift @site_urls;
        my ($ssl, $domain) = $shortest =~ m!^http(s?)://(.+?)/!g;
        my $dot = index( $domain, '.' );
        # XXX: ignoring domain that starts with ".".
        if ( $dot > 0 ) {
            $domain =~ s!^(?:[\.\w]*?)([^\.]+?)(\.\w+)$!$1$2!;
        }
        my ( $subdomain, $path ) = $shortest =~ m!^https?://(.*)\.?$domain/(.*)$!;
        my $blog = delete $site_urls{ $shortest };

        return $self->error($self->translate_escape("Error loading class: [_1].", 'Website'))
            unless $website_class;

        my $website = $website_class->create_default_website(MT->translate('New WebSite [_1]', $domain));
        $website->site_path($blog->site_path);
        $website->site_url("http$ssl://$domain/");
        $website->save
            or return $self->error($self->translate_escape("An error occured during generating a website upon upgrade: [_1]", $website->errstr));

        foreach ( @sysadmins ) {
        $assoc_class->link( $_ => $role => $website ) or die $role->name . $website->name;
        }
        $self->progress($self->translate_escape('Generated a website [_1]', $domain));

        $path = $path . '/' if $path && $path !~ m!/$!;
        my $old_site_url = $blog->site_url;
        $blog->site_url("$subdomain/::/$path");
        $blog->parent_id($website->id);
        $blog->save
            or return $self->error($self->translate_escape("An error occured during migrating a blog's site_url: [_1]", $website->errstr));
        $self->progress($self->translate_escape('Moved blog [_1] ([_2]) under website [_3]', $blog->name, $old_site_url, $domain));

        my @children = grep { $_ =~ m!https?://.+$domain/! } @site_urls;
        foreach my $child_url ( @children )  {
            my ( $subdomain, $path ) = $child_url =~ m!^https?://(.*)\.?$domain/(.*)$!;
            my $blog = delete $site_urls{ $child_url };
            $path = $path . '/' if $path && $path !~ m!/$!;
            my $old_site_url = $blog->site_url;
            $blog->site_url("$subdomain/::/$path");
            $blog->parent_id($website->id);
            $blog->save
                or return $self->error($self->translate_escape("An error occured during migrating a blog's site_url: [_1]", $website->errstr));
            $self->progress($self->translate_escape('Moved blog [_1] ([_2]) under website [_3]', $blog->name, $old_site_url, $domain));
        }
    }
    1;
}

1;
__END__
