( function _Censor_test_s_()
{

'use strict';

if( typeof module !== 'undefined' )
{
  const _ = require( '../identity/entry/IdentityBasic.s' );
  _.include( 'wTesting' );
}

const _global = _global_;
const _ = _global_.wTools;

// --
// context
// --

function onSuiteBegin()
{
  let context = this;
  context.suiteTempPath = _.path.tempOpen( _.path.join( __dirname, '../..' ), 'censor' );
}

//

function onSuiteEnd()
{
  let context = this;
  _.assert( _.strHas( context.suiteTempPath, '/censor' ) )
  _.path.tempClose( context.suiteTempPath );
}

// --
// tests
// --

function profileHookPathMake( test )
{
  const a = test.assetFor( false );
  const profileDir = `test-${ _.intRandom( 1000000 ) }`;

  /* */

  test.case = 'type - git';
  var got = _.censor.profileHookPathMake({ profileDir, type : 'git' });
  var exp = a.abs( a.path.dirUserHome(), _.censor.storageDir, profileDir, 'hook/GitHook.js' );
  test.identical( got, exp );

  test.case = 'type - npm';
  var got = _.censor.profileHookPathMake({ profileDir, type : 'npm' });
  var exp = a.abs( a.path.dirUserHome(), _.censor.storageDir, profileDir, 'hook/NpmHook.js' );
  test.identical( got, exp );

  test.case = 'type - cargo';
  var got = _.censor.profileHookPathMake({ profileDir, type : 'cargo' });
  var exp = a.abs( a.path.dirUserHome(), _.censor.storageDir, profileDir, 'hook/CargoHook.js' );
  test.identical( got, exp );

  /* - */

  if( !Config.debug )
  return;

  test.case = 'without arguments';
  test.shouldThrowErrorSync( () => _.censor.profileHookPathMake() );

  test.case = 'extra arguments';
  var o = { profileDir, type : 'git' };
  test.shouldThrowErrorSync( () => _.censor.profileHookPathMake( o, o ) );

  test.case = 'wrong type of options map';
  test.shouldThrowErrorSync( () => _.censor.profileHookPathMake([ { profileDir, type : 'git' } ]) );

  test.case = 'unknown option in options map';
  test.shouldThrowErrorSync( () => _.censor.profileHookPathMake([ { profileDir, type : 'git', unknown : 1 } ]) );

  test.case = 'o.type has not valid value';
  test.shouldThrowErrorSync( () => _.censor.profileHookPathMake({ profileDir, type : null }) );
}

//

function profileHookGet( test )
{
  const a = test.assetFor( false );
  const profileDir = `test-${ _.intRandom( 1000000 ) }`;
  const userProfileDir = a.fileProvider.configUserPath( `.censor/${ profileDir }` );
  const hook = 'console.log( `hook` );';

  /* */

  test.case = 'get git hook, hooks do not exist';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var files = a.find( userProfileDir );
  test.identical( files, [ '.', './config.yaml' ] );
  var got = _.censor.profileHookGet({ profileDir, type : 'git' });
  test.true( _.strBegins( got, /function .*( identity, options )/ ) );
  var files = a.find( userProfileDir );
  var exp = [ '.', './config.yaml' ];
  test.identical( files, exp );
  _.censor.profileDel( profileDir );

  test.case = 'get npm hook, hooks do not exist';
  var identity = { name : 'user', login : 'userLogin', type : 'npm' };
  _.identity.identityNew({ profileDir, identity });
  var files = a.find( userProfileDir );
  test.identical( files, [ '.', './config.yaml' ] );
  var got = _.censor.profileHookGet({ profileDir, type : 'npm' });
  test.true( _.strBegins( got, /function .*( identity, options )/ ) );
  var files = a.find( userProfileDir );
  var exp = [ '.', './config.yaml' ];
  test.identical( files, exp );
  _.censor.profileDel( profileDir );

  test.case = 'set hooks for general type, get all hooks';
  var identity = { name : 'user', type : 'super', identities : {} };
  _.identity.identityNew({ profileDir, identity });
  var files = a.find( userProfileDir );
  test.identical( files, [ '.', './config.yaml' ] );
  var got = _.censor.profileHookSet({ profileDir, hook, type : 'super' });
  var got = _.censor.profileHookGet({ profileDir, type : 'super' });
  test.true( _.array.is( got ) );
  test.identical( got.length, 4 );
  test.identical( got[ 0 ], hook );
  test.identical( got[ 0 ], got[ 1 ] );
  test.identical( got[ 1 ], got[ 2 ] );
  var files = a.find( userProfileDir );
  var exp =
  [
    '.',
    './config.yaml',
    './hook',
    './hook/CargoHook.js',
    './hook/GitHook.js',
    './hook/NpmHook.js',
    './hook/SshHook.js',
  ];
  test.identical( files, exp );
  _.censor.profileDel( profileDir );

  /* - */

  if( !Config.debug )
  return;

  test.case = 'without arguments';
  test.shouldThrowErrorSync( () => _.censor.profileHookGet() );

  test.case = 'extra arguments';
  var o = { profileDir, type : 'git' };
  test.shouldThrowErrorSync( () => _.censor.profileHookGet( o, o ) );

  test.case = 'wrong type of options map';
  test.shouldThrowErrorSync( () => _.censor.profileHookGet([ { profileDir, type : 'git' } ]) );

  test.case = 'unknown option in options map';
  test.shouldThrowErrorSync( () => _.censor.profileHookGet({ profileDir, type : 'git', unknown : 1 }) );

  test.case = 'wrong type of o.type';
  test.shouldThrowErrorSync( () => _.censor.profileHookGet({ profileDir, type : null }) );

  test.case = 'unknown type of o.type';
  test.shouldThrowErrorSync( () => _.censor.profileHookGet({ profileDir, type : 'unknown' }) );
}

//

function profileHookCallWithIdentityWithDefaultGitHook( test )
{
  const a = test.assetFor( false );

  if( !_.process.insideTestContainer() )
  return test.true( true );

  a.fileProvider.dirMake( a.abs( '.' ) );
  const profileDir = `test-${ _.intRandom( 1000000 ) }`;
  const userProfileDir = a.fileProvider.configUserPath( `.censor/${ profileDir }` );

  const originalConfig = a.fileProvider.fileRead( a.fileProvider.configUserPath( '.gitconfig' ) );

  /* - */

  begin().then( () =>
  {
    test.case = 'call git hook';
    var identity = { name : 'user', login : 'userLogin', email : 'user@domain.com', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml' ] );
    var config = _.censor.configRead({ profileDir });
    var got = _.censor.profileHookCallWithIdentity({ profileDir, identity : config.identity.user });
    test.identical( got, undefined );
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml' ] );
    _.censor.profileDel( profileDir );
    return null;
  });
  a.shell( 'git config --global --list' )
  .then( ( op ) =>
  {
    test.identical( _.strCount( op.output, 'user.name=userLogin' ), 1 );
    test.identical( _.strCount( op.output, 'user.email=user@domain.com' ), 1 );
    test.identical( _.strCount( op.output, 'url.https://userLogin@github.com.insteadof=https://github.com' ), 1 );
    test.identical( _.strCount( op.output, 'url.https://userLogin@bitbucket.org.insteadof=https://bitbucket.org' ), 1 );
    return null;
  });

  /* */

  begin();
  a.shell( 'git config --global user.name anotherUser' )
  a.ready.then( () =>
  {
    test.case = 'git user name exists';
    var identity = { name : 'user', login : 'userLogin', email : 'user@domain.com', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml' ] );
    var config = _.censor.configRead({ profileDir });
    var got = _.censor.profileHookCallWithIdentity({ profileDir, identity : config.identity.user });
    test.identical( got, undefined );
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml' ] );
    _.censor.profileDel( profileDir );
    return null;
  });
  a.shell( 'git config --global --list' )
  .then( ( op ) =>
  {
    test.identical( _.strCount( op.output, 'user.name=userLogin' ), 1 );
    test.identical( _.strCount( op.output, 'user.email=user@domain.com' ), 1 );
    test.identical( _.strCount( op.output, 'url.https://userLogin@github.com.insteadof=https://github.com' ), 1 );
    test.identical( _.strCount( op.output, 'url.https://userLogin@bitbucket.org.insteadof=https://bitbucket.org' ), 1 );
    return null;
  });

  /* */

  begin().then( () =>
  {
    test.case = 'call twice';
    var identity = { name : 'user', login : 'userLogin', email : 'user@domain.com', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml' ] );
    var config = _.censor.configRead({ profileDir });
    var got = _.censor.profileHookCallWithIdentity({ profileDir, identity : config.identity.user });
    var got = _.censor.profileHookCallWithIdentity({ profileDir, identity : config.identity.user });
    test.identical( got, undefined );
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml' ] );
    _.censor.profileDel( profileDir );
    return null;
  });
  a.shell( 'git config --global --list' )
  .then( ( op ) =>
  {
    test.identical( _.strCount( op.output, 'user.name=userLogin' ), 1 );
    test.identical( _.strCount( op.output, 'user.email=user@domain.com' ), 1 );
    test.identical( _.strCount( op.output, 'url.https://userLogin@github.com.insteadof=https://github.com' ), 1 );
    test.identical( _.strCount( op.output, 'url.https://userLogin@bitbucket.org.insteadof=https://bitbucket.org' ), 1 );
    return null;
  });

  /* */

  begin().then( () =>
  {
    test.case = 'change identity';
    var identity = { name : 'user', login : 'userLogin', email : 'user@domain.com', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var identity = { name : 'user2', login : 'userLogin2', email : 'user2@domain.com', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml' ] );
    var config = _.censor.configRead({ profileDir });
    var got = _.censor.profileHookCallWithIdentity({ profileDir, identity : config.identity.user });
    var got = _.censor.profileHookCallWithIdentity({ profileDir, identity : config.identity.user2 });
    test.identical( got, undefined );
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml' ] );
    _.censor.profileDel( profileDir );
    return null;
  });
  a.shell( 'git config --global --list' )
  .then( ( op ) =>
  {
    test.identical( _.strCount( op.output, 'user.name=userLogin2' ), 1 );
    test.identical( _.strCount( op.output, 'user.email=user2@domain.com' ), 1 );
    test.identical( _.strCount( op.output, 'url.https://userLogin2@github.com.insteadof=https://github.com' ), 1 );
    test.identical( _.strCount( op.output, 'url.https://userLogin2@bitbucket.org.insteadof=https://bitbucket.org' ), 1 );
    return null;
  });

  /* */

  a.ready.finally( ( err, arg ) =>
  {
    a.fileProvider.fileWrite( a.fileProvider.configUserPath( '.gitconfig' ), originalConfig );
    if( err )
    throw _.err( err );
    return arg;
  });

  /* - */

  return a.ready;

  /* */

  function begin()
  {
    return a.ready.then( () =>
    {
      a.fileProvider.fileWrite( a.fileProvider.configUserPath( '.gitconfig' ), '' );
      return null;
    });
  }
}

//

function profileHookCallWithIdentityWithDefaultNpmHook( test )
{
  const a = test.assetFor( false );

  if( !_.process.insideTestContainer() )
  return test.true( true );

  a.fileProvider.dirMake( a.abs( '.' ) );
  const profileDir = `test-${ _.intRandom( 1000000 ) }`;
  const userProfileDir = a.fileProvider.configUserPath( `.censor/${ profileDir }` );
  const login = 'wtools-bot';
  const token = process.env.PRIVATE_WTOOLS_BOT_NPM_TOKEN;
  const email = process.env.PRIVATE_WTOOLS_BOT_EMAIL;
  const pass = process.env.NPM_PASS;

  if( !token || !email || !pass )
  return test.true( true );

  /* - */

  a.ready.then( () =>
  {
    test.case = 'call npm hook';
    var identity = { name : 'user', login, email, token, type : 'npm' };
    _.identity.identityNew({ profileDir, identity });
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml' ] );
    var config = _.censor.configRead({ profileDir });
    var got = _.censor.profileHookCallWithIdentity({ profileDir, identity : config.identity.user });
    test.identical( got, undefined );
    _.censor.profileDel( profileDir );
    return null;
  });
  a.shell( 'npm whoami' )
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.output.trim(), login );
    return null;
  });

  /* */

  a.ready.then( () =>
  {
    test.case = 'call npm hook twice';
    var identity = { name : 'user', login, email, token, type : 'npm' };
    _.identity.identityNew({ profileDir, identity });
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml' ] );
    var config = _.censor.configRead({ profileDir });
    var got = _.censor.profileHookCallWithIdentity({ profileDir, identity : config.identity.user });
    var got = _.censor.profileHookCallWithIdentity({ profileDir, identity : config.identity.user });
    test.identical( got, undefined );
    _.censor.profileDel( profileDir );
    return null;
  });
  a.shell( 'npm whoami' )
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.output.trim(), login );
    return null;
  });

  /* - */

  return a.ready;
}

//

function profileHookCallWithIdentityWithDefaultSshHook( test )
{
  const a = test.assetFor( false );

  if( !_.process.insideTestContainer() )
  return test.true( true );

  a.fileProvider.dirMake( a.abs( '.' ) );
  const profileDir = `test-${ _.intRandom( 1000000 ) }`;
  const userProfileDir = a.fileProvider.configUserPath( `.censor/${ profileDir }` );
  let originalExists = false;
  const originalPath = a.fileProvider.configUserPath( '.ssh' );
  const backupPath = a.fileProvider.configUserPath( '.ssh.bak' );
  if( _.fileProvider.fileExists( originalPath ) )
  originalExists = true;

  begin();

  /* - */

  writeKey( 'id_rsa' ).then( () =>
  {
    test.case = 'call ssh hook';
    _.identity.identityFrom({ profileDir, selector : 'user', type : 'ssh' });
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml', './ssh', './ssh/user', './ssh/user/id_rsa' ] );
    a.fileProvider.fileWrite( a.abs( originalPath, 'id_rsa' ), 'another data' );
    var config = _.censor.configRead({ profileDir });
    var got = _.censor.profileHookCallWithIdentity({ profileDir, identity : config.identity.user });
    test.identical( got, undefined );
    var data = a.fileProvider.fileRead( a.abs( originalPath, 'id_rsa' ) );
    test.identical( data, 'id_rsa' );
    _.censor.profileDel( profileDir );
    return null;
  });

  /* */

  writeKey( 'id_rsa' ).then( () =>
  {
    test.case = 'call twice';
    _.identity.identityFrom({ profileDir, selector : 'user', type : 'ssh' });
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml', './ssh', './ssh/user', './ssh/user/id_rsa' ] );
    a.fileProvider.fileWrite( a.abs( originalPath, 'id_rsa' ), 'another data' );
    var config = _.censor.configRead({ profileDir });
    var got = _.censor.profileHookCallWithIdentity({ profileDir, identity : config.identity.user });
    var got = _.censor.profileHookCallWithIdentity({ profileDir, identity : config.identity.user });
    test.identical( got, undefined );
    var data = a.fileProvider.fileRead( a.abs( originalPath, 'id_rsa' ) );
    test.identical( data, 'id_rsa' );
    _.censor.profileDel( profileDir );
    return null;
  });

  /* */

  writeKey( 'id_rsa' ).then( () =>
  {
    test.case = 'change identity';
    _.identity.identityFrom({ profileDir, selector : 'user', type : 'ssh' });
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml', './ssh', './ssh/user', './ssh/user/id_rsa' ] );
    return null;
  });
  writeKey( 'id_rsa' ).then( () =>
  {
    test.case = 'call twice';
    _.identity.identityFrom({ profileDir, selector : 'user2', type : 'ssh' });
    var files = a.find( userProfileDir );
    var exp =
    [
      '.',
      './config.yaml',
      './ssh',
      './ssh/user',
      './ssh/user/id_rsa',
      './ssh/user2',
      './ssh/user2/id_rsa'
    ];
    test.identical( files, exp );
    a.fileProvider.fileWrite( a.abs( originalPath, 'some_file' ), 'data' );
    var config = _.censor.configRead({ profileDir });
    var got = _.censor.profileHookCallWithIdentity({ profileDir, identity : config.identity.user });
    test.identical( got, undefined );
    var files = a.find( userProfileDir );
    var exp =
    [
      '.',
      './config.yaml',
      './ssh',
      './ssh/user',
      './ssh/user/id_rsa',
      './ssh/user2',
      './ssh/user2/id_rsa'
    ];
    test.identical( files, exp );
    var data = a.fileProvider.fileRead( a.abs( originalPath, 'id_rsa' ) );
    test.identical( data, 'id_rsa' );
    _.censor.profileDel( profileDir );
    return null;
  });

  /* */

  a.ready.finally( ( err, arg ) =>
  {
    a.fileProvider.filesDelete( originalPath );
    if( originalExists )
    {
      a.fileProvider.filesReflect
      ({
        reflectMap : { [ backupPath ] : originalPath }
      });
      a.fileProvider.filesDelete( backupPath );
    }
    if( err )
    throw _.err( err );
    return arg;
  });

  /* - */

  return a.ready;

  /* */

  function begin()
  {
    return a.ready.then( () =>
    {
      if( originalExists )
      {
        a.fileProvider.filesReflect
        ({
          reflectMap : { [ originalPath ] : backupPath }
        });
        a.fileProvider.filesDelete( originalPath );
      }
      return null;
    });
  }

  /* */

  function writeKey( name )
  {
    return a.ready.then( () =>
    {
      a.fileProvider.filesDelete( originalPath );
      a.fileProvider.fileWrite( a.abs( originalPath, name ), name );
      return null;
    });
  }
}

//

function profileHookCallWithIdentityWithUserHooks( test )
{
  const a = test.assetFor( false );
  const profileDir = `test-${ _.intRandom( 1000000 ) }`;
  const userProfileDir = a.fileProvider.configUserPath( `.censor/${ profileDir }` );
  const hook =
`function onIdentity( identity )
{
  const _ = this;
  _.identity.identitySet({ profileDir : '${ profileDir }', selector : 'user', set : { email : 'user@domain.com' } });
}
module.exports = onIdentity;`;
  const hook2 =
`function onIdentity( identity )
{
  const _ = this;
  _.identity.identitySet({ profileDir : '${ profileDir }', selector : 'user', set : { token : 'userToken' } });
}
module.exports = onIdentity;`;
  const hook3 =
`function onIdentity( identity )
{
  const _ = this;
  _.identity.identitySet({ profileDir : '${ profileDir }', selector : 'user', set : { 'ssh.path' : 'path' } });
}
module.exports = onIdentity;`;

  /* */

  test.case = 'call git hook';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  _.censor.profileHookSet({ profileDir, hook, type : 'git' });
  var config = _.censor.configRead({ profileDir });
  test.identical( config.identity.user.email, undefined );
  var got = _.censor.profileHookCallWithIdentity({ profileDir, identity : config.identity.user });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  test.identical( config.identity.user.email, 'user@domain.com' );
  _.censor.profileDel( profileDir );

  test.case = 'call npm hook';
  var identity = { name : 'user', login : 'userLogin', type : 'npm' };
  _.identity.identityNew({ profileDir, identity });
  _.censor.profileHookSet({ profileDir, hook, type : 'npm' });
  var config = _.censor.configRead({ profileDir });
  test.identical( config.identity.user.email, undefined );
  var got = _.censor.profileHookCallWithIdentity({ profileDir, identity : config.identity.user });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  test.identical( config.identity.user.email, 'user@domain.com' );
  _.censor.profileDel( profileDir );

  test.case = 'call git hooks for different identities';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var identity = { name : 'user2', login : 'userLogin2', type : 'npm' };
  _.identity.identityNew({ profileDir, identity });
  _.censor.profileHookSet({ profileDir, hook, type : 'git' });
  _.censor.profileHookSet({ profileDir, hook : hook2, type : 'npm' });
  var config = _.censor.configRead({ profileDir });
  test.identical( config.identity.user.email, undefined );
  test.identical( config.identity.user.token, undefined );
  test.identical( config.identity.user2.email, undefined );
  test.identical( config.identity.user2.token, undefined );
  _.censor.profileHookCallWithIdentity({ profileDir, identity : config.identity.user });
  _.censor.profileHookCallWithIdentity({ profileDir, identity : config.identity.user2 });
  var config = _.censor.configRead({ profileDir });
  test.identical( config.identity.user.email, 'user@domain.com' );
  test.identical( config.identity.user.token, 'userToken' );
  test.identical( config.identity.user2.email, undefined );
  test.identical( config.identity.user2.token, undefined );
  _.censor.profileDel( profileDir );

  /* - */

  if( Config.debug )
  {
    test.case = 'without arguments';
    test.shouldThrowErrorSync( () => _.censor.profileHookCallWithIdentity() );

    test.case = 'extra arguments';
    var o = { profileDir, type : 'git', selector : 'user' };
    test.shouldThrowErrorSync( () => _.censor.profileHookCallWithIdentity( o, o ) );

    test.case = 'wrong type of options map';
    test.shouldThrowErrorSync( () => _.censor.profileHookCallWithIdentity([ { profileDir, type : 'git', selector : 'user' } ]) );

    test.case = 'unknown option in options map';
    test.shouldThrowErrorSync( () => _.censor.profileHookCallWithIdentity({ profileDir, type : 'git', selector : 'user', unknown : 1 }) );

    test.case = 'wrong type of o.type';
    test.shouldThrowErrorSync( () => _.censor.profileHookCallWithIdentity({ profileDir, type : null, selector : 'user' }) );

    test.case = 'unknown type of o.type';
    test.shouldThrowErrorSync( () => _.censor.profileHookCallWithIdentity({ profileDir, type : 'unknown', selector : 'user' }) );

    test.case = 'o.selector is glob';
    test.shouldThrowErrorSync( () => _.censor.profileHookCallWithIdentity({ profileDir, type : 'unknown', selector : 'user*' }) );

    test.case = 'identity type is not equal to o.type, not general identity type';
    _.identity.identityNew({ profileDir, identity : { name : 'user', login : 'userLogin', type : 'npm' } });
    test.shouldThrowErrorSync( () => _.censor.profileHookCallWithIdentity({ profileDir, type : 'git', selector : 'user' }) );
    _.censor.profileDel( profileDir );
    _.identity.identityNew({ profileDir, identity : { name : 'user', login : 'userLogin', type : 'npm' } });
    test.shouldThrowErrorSync( () => _.censor.profileHookCallWithIdentity({ profileDir, type : 'general', selector : 'user' }) );
    _.censor.profileDel( profileDir );

    test.case = 'hook return no routine';
    _.identity.identityNew({ profileDir, identity : { name : 'user', login : 'userLogin', type : 'git' } });
    _.censor.profileHookSet({ profileDir, hook : 'console.log( `hook` );', type : 'git' });
    test.shouldThrowErrorSync( () => _.censor.profileHookCallWithIdentity({ profileDir, type : 'git', selector : 'user' }) );
    _.censor.profileDel( profileDir );
  }
}

//

function profileHookSet( test )
{
  const a = test.assetFor( false );
  const profileDir = `test-${ _.intRandom( 1000000 ) }`;
  const userProfileDir = a.fileProvider.configUserPath( `.censor/${ profileDir }` );
  const hook = 'console.log( `hook` );';

  /* */

  test.case = 'set git hook';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var files = a.find( userProfileDir );
  test.identical( files, [ '.', './config.yaml' ] );
  var got = _.censor.profileHookSet({ profileDir, hook, type : 'git' });
  test.identical( got, undefined );
  var files = a.find( userProfileDir );
  var exp =
  [
    '.',
    './config.yaml',
    './hook',
    './hook/GitHook.js',
  ];
  test.identical( files, exp );
  _.censor.profileDel( profileDir );

  test.case = 'set npm hook';
  var identity = { name : 'user', login : 'userLogin', type : 'npm' };
  _.identity.identityNew({ profileDir, identity });
  var files = a.find( userProfileDir );
  test.identical( files, [ '.', './config.yaml' ] );
  var got = _.censor.profileHookSet({ profileDir, hook, type : 'npm' });
  test.identical( got, undefined );
  var files = a.find( userProfileDir );
  var exp =
  [
    '.',
    './config.yaml',
    './hook',
    './hook/NpmHook.js',
  ];
  test.identical( files, exp );
  _.censor.profileDel( profileDir );

  test.case = 'set hooks for general type';
  var identity = { name : 'user', type : 'super', identities : {} };
  _.identity.identityNew({ profileDir, identity });
  var files = a.find( userProfileDir );
  test.identical( files, [ '.', './config.yaml' ] );
  var got = _.censor.profileHookSet({ profileDir, hook, type : 'super' });
  test.identical( got, undefined );
  var files = a.find( userProfileDir );
  var exp =
  [
    '.',
    './config.yaml',
    './hook',
    './hook/CargoHook.js',
    './hook/GitHook.js',
    './hook/NpmHook.js',
    './hook/SshHook.js',
  ];
  test.identical( files, exp );
  _.censor.profileDel( profileDir );

  /* - */

  if( !Config.debug )
  return;

  test.case = 'without arguments';
  test.shouldThrowErrorSync( () => _.censor.profileHookSet() );

  test.case = 'extra arguments';
  var o = { profileDir, hook, type : 'git' };
  test.shouldThrowErrorSync( () => _.censor.profileHookSet( o, o ) );

  test.case = 'wrong type of options map';
  test.shouldThrowErrorSync( () => _.censor.profileHookSet([ { profileDir, hook, type : 'git' } ]) );

  test.case = 'unknown option in options map';
  test.shouldThrowErrorSync( () => _.censor.profileHookSet({ profileDir, hook, type : 'git', unknown : 1 }) );

  test.case = 'wrong type of o.type';
  test.shouldThrowErrorSync( () => _.censor.profileHookSet({ profileDir, hook, type : null }) );
}

// --
// declare
// --

const Proto =
{
  name : 'Tools.mid.Censor',
  silencing : 1,
  enabled : 1,

  onSuiteBegin,
  onSuiteEnd,
  routineTimeOut : 60000,

  context :
  {
    suiteTempPath : null,
  },

  tests :
  {
    profileHookPathMake,
    profileHookGet,
    profileHookCallWithIdentityWithDefaultGitHook,
    profileHookCallWithIdentityWithDefaultNpmHook,
    profileHookCallWithIdentityWithDefaultSshHook,
    profileHookCallWithIdentityWithUserHooks,
    profileHookSet,
  },
};

const Self = wTestSuite( Proto );
if( typeof module !== 'undefined' && !module.parent )
wTester.test( Self.name );

})();
