( function _Identity_test_s_()
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
  context.suiteTempPath = _.path.tempOpen( _.path.join( __dirname, '../..' ), 'identity' );
}

//

function onSuiteEnd()
{
  let context = this;
  _.assert( _.strHas( context.suiteTempPath, '/identity' ) )
  _.path.tempClose( context.suiteTempPath );
}

// --
// tests
// --

function identityCopy( test )
{
  const profileDir = `test-${ _.intRandom( 1000000 ) }`;

  /* */

  test.case = 'copy identity from existed config, single identity, selector matches identity';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.identical( config.identity, { user : { login : 'userLogin', type : 'git' } } );
  var got = _.identity.identityCopy({ profileDir, identitySrcName : 'user', identityDstName : 'user3' });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  test.identical( _.props.keys( config.identity ), [ 'user', 'user3' ] );
  test.identical( config.identity.user, { login : 'userLogin', type : 'git' } );
  test.identical( config.identity.user, config.identity.user3 );
  _.censor.profileDel( profileDir );

  test.case = 'copy identity from existed config, several identities, selector matches identity';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var identity = { name : 'user2', login : 'userLogin2', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.identical( _.props.keys( config.identity ), [ 'user', 'user2' ] );
  var got = _.identity.identityCopy({ profileDir, identitySrcName : 'user', identityDstName : 'user3' });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  test.identical( _.props.keys( config.identity ), [ 'user', 'user2', 'user3' ] );
  test.identical( config.identity.user, { login : 'userLogin', type : 'git' } );
  test.identical( config.identity.user2, { login : 'userLogin2', type : 'git' } );
  test.identical( config.identity.user, config.identity.user3 );
  _.censor.profileDel( profileDir );

  /* */

  test.case = 'config exists, identity exists, selector matches identity, dst identity exists, force - 1';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var identity = { name : 'user2', login : 'userLogin2', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.identical( _.props.keys( config.identity ), [ 'user', 'user2' ] );
  test.notIdentical( config.identity.user, config.identity.user3 );
  var got = _.identity.identityCopy({ profileDir, identitySrcName : 'user', identityDstName : 'user2', force : 1 });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  test.identical( _.props.keys( config.identity ), [ 'user', 'user2' ] );
  test.identical( config.identity.user, config.identity.user2 );
  _.censor.profileDel( profileDir );

  /* */

  test.case = 'config exists, superidentity exists, selector matches identity, dst identity not exists';
  var identity = { name : 'user', type : 'super', identities : { 'foo' : true } };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.identical( _.props.keys( config.identity ), [ 'user' ] );
  var got = _.identity.identityCopy({ profileDir, identitySrcName : 'user', identityDstName : 'user2' });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  test.identical( _.props.keys( config.identity ), [ 'user', 'user2' ] );
  test.identical( config.identity.user, config.identity.user2 );
  _.censor.profileDel( profileDir );

  /* - */

  if( !Config.debug )
  return;

  test.case = 'without arguments';
  test.shouldThrowErrorSync( () => _.identity.identityCopy() );

  test.case = 'extra arguments';
  var o = { profileDir, identitySrcName : 'user', identityDstName : 'user2' };
  test.shouldThrowErrorSync( () => _.identity.identityCopy( o, o ) );

  test.case = 'wrong type of options map';
  var o = { profileDir, identitySrcName : 'user', identityDstName : 'user2' };
  test.shouldThrowErrorSync( () => _.identity.identityCopy([ o ]) );

  test.case = 'unknown option in options map';
  var o = { profileDir, identitySrcName : 'user', identityDstName : 'user2', unknown : 1 };
  test.shouldThrowErrorSync( () => _.identity.identityCopy( o ) );

  test.case = 'o.identitySrcName is not defined string';
  var o = { profileDir, identitySrcName : '', identityDstName : 'user2' };
  test.shouldThrowErrorSync( () => _.identity.identityCopy( o ) );

  test.case = 'o.identitySrcName is string with glob, get several identities';
  _.identity.identityNew({ profileDir, identity : { name : 'user', login : 'userLogin', type : 'git' } });
  _.identity.identityNew({ profileDir, identity : { name : 'user2', login : 'userLogin2', type : 'git' } });
  var o = { profileDir, identitySrcName : 'user*', identityDstName : 'user3' };
  test.shouldThrowErrorSync( () => _.identity.identityCopy( o ) );
  _.censor.profileDel( profileDir );

  test.case = 'o.identityDstName is not defined string';
  var o = { profileDir, identitySrcName : 'user', identityDstName : '' };
  test.shouldThrowErrorSync( () => _.identity.identityCopy( o ) );

  test.case = 'o.identityDstName is string with glob';
  var o = { profileDir, identitySrcName : 'user', identityDstName : 'user2*' };
  test.shouldThrowErrorSync( () => _.identity.identityCopy( o ) );

  test.case = 'config is not existed';
  test.shouldThrowErrorSync( () => _.identity.identityCopy({ profileDir, identitySrcName : 'user', identityDstName : 'user3' }) );

  test.case = 'config exists, identities not exist';
  _.censor.configSet({ profileDir, set : { about : { name : profileDir } } });
  test.shouldThrowErrorSync( () => _.identity.identityCopy({ profileDir, identitySrcName : 'user', identityDstName : 'user3' }) );
  _.censor.profileDel( profileDir );

  test.case = 'config exists, identity exists, selector matches not identity';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  test.shouldThrowErrorSync( () => _.identity.identityCopy({ profileDir, identitySrcName : 'user2', identityDstName : 'user3' }) );
  _.censor.profileDel( profileDir );

  test.case = 'config exists, identity exists, selector matches identity, dst identity exists, force - 0';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var identity = { name : 'user2', login : 'userLogin2', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  test.shouldThrowErrorSync( () => _.identity.identityCopy({ profileDir, identitySrcName : 'user', identityDstName : 'user2' }) );
  _.censor.profileDel( profileDir );
}

//

function identityGet( test )
{
  const profileDir = `test-${ _.intRandom( 1000000 ) }`;

  /* */

  getAllIdentities( profileDir );
  getAllIdentities({ profileDir });
  getAllIdentities({ profileDir, selector : null });
  getAllIdentities({ profileDir, selector : '' });

  /* */

  function getAllIdentities( arg )
  {
    test.open( `${ _.entity.exportStringSolo( arg ) }` );

    test.case = 'get identities from not existed config';
    var config = _.censor.configRead({ profileDir });
    test.identical( config, null );
    var got = _.identity.identityGet( _.entity.make( arg ) );
    test.identical( got, undefined );
    _.censor.profileDel( profileDir );

    test.case = 'get identities from existed config, identities not exist';
    _.censor.configSet({ profileDir, set : { about : { name : profileDir } } });
    var config = _.censor.configRead({ profileDir });
    test.identical( config, { about : { name : profileDir }, path : {} } );
    var got = _.identity.identityGet( _.entity.make( arg ) );
    test.identical( got, undefined );
    _.censor.profileDel( profileDir );

    test.case = 'get identities from existed config, single identity';
    var identity = { name : 'user', login : 'userLogin', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var config = _.censor.configRead({ profileDir });
    test.true( _.map.is( config.identity ) );
    var got = _.identity.identityGet( _.entity.make( arg ) );
    test.identical( got, { user : { login : 'userLogin', type : 'git' } } );
    _.censor.profileDel( profileDir );

    test.case = 'get identities from existed config, several identities';
    var identity = { name : 'user', login : 'userLogin', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var identity = { name : 'user2', login : 'userLogin2', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var config = _.censor.configRead({ profileDir });
    test.true( _.map.is( config.identity ) );
    var got = _.identity.identityGet( _.entity.make( arg ) );
    var exp =
    {
      user : { login : 'userLogin', type : 'git' },
      user2 : { login : 'userLogin2', type : 'git' }
    };
    test.identical( got, exp );
    _.censor.profileDel( profileDir );

    test.close( `${ _.entity.exportStringSolo( arg ) }` );
  }

  /* - */

  test.open( 'with selector' );

  test.case = 'get identity from not existed config';
  var config = _.censor.configRead({ profileDir });
  test.identical( config, null );
  var got = _.identity.identityGet({ profileDir, selector : 'user' });
  test.identical( got, undefined );
  _.censor.profileDel( profileDir );

  test.case = 'get identity from existed config, identities not exist';
  _.censor.configSet({ profileDir, set : { about : { name : profileDir } } });
  var config = _.censor.configRead({ profileDir });
  test.identical( config, { about : { name : profileDir }, path : {} } );
  var got = _.identity.identityGet({ profileDir, selector : 'user' });
  test.identical( got, undefined );
  _.censor.profileDel( profileDir );

  test.case = 'get identity from existed config, single identity, selector matches identity';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.true( _.map.is( config.identity ) );
  var got = _.identity.identityGet({ profileDir, selector : 'user' });
  test.identical( got, { login : 'userLogin', type : 'git' } );
  _.censor.profileDel( profileDir );

  test.case = 'get identity from existed config, single identity, selector matches not identity';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.true( _.map.is( config.identity ) );
  var got = _.identity.identityGet({ profileDir, selector : 'user2' });
  test.identical( got, undefined );
  _.censor.profileDel( profileDir );

  test.case = 'get identity from existed config, several identities, selector matches identity';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var identity = { name : 'user2', login : 'userLogin2', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.true( _.map.is( config.identity ) );
  var got = _.identity.identityGet({ profileDir, selector : 'user2' });
  test.identical( got, { login : 'userLogin2', type : 'git' } );
  _.censor.profileDel( profileDir );

  test.case = 'get identity from existed config, several identities, selector matches not identity';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var identity = { name : 'user2', login : 'userLogin2', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.true( _.map.is( config.identity ) );
  var got = _.identity.identityGet({ profileDir, selector : 'user3' });
  test.identical( got, undefined );
  _.censor.profileDel( profileDir );

  test.case = 'get identity from existed config, several identities, selector with glob, matches identities';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var identity = { name : 'user2', login : 'userLogin2', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.true( _.map.is( config.identity ) );
  var got = _.identity.identityGet({ profileDir, selector : 'user*' });
  var exp =
  {
    user : { login : 'userLogin', type : 'git' },
    user2 : { login : 'userLogin2', type : 'git' }
  };
  test.identical( got, exp );
  _.censor.profileDel( profileDir );

  test.case = 'get identity from existed config, several identities, selector with glob, matches not identities';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var identity = { name : 'user2', login : 'userLogin2', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.true( _.map.is( config.identity ) );
  var got = _.identity.identityGet({ profileDir, selector : 'git*' });
  test.identical( got, {} );
  _.censor.profileDel( profileDir );

  test.close( 'with selector' );

  /* - */

  if( !Config.debug )
  return;

  test.case = 'without arguments';
  test.shouldThrowErrorSync( () => _.identity.identityGet() );

  test.case = 'extra arguments';
  test.shouldThrowErrorSync( () => _.identity.identityGet( profileDir, profileDir ) );

  test.case = 'wrong type of options map';
  test.shouldThrowErrorSync( () => _.identity.identityGet([ profileDir ]) );

  test.case = 'unknown option in options map';
  test.shouldThrowErrorSync( () => _.identity.identityGet({ profileDir, selector : '', unknown : 1 }) );

  test.case = 'wrong type of o.selector';
  test.shouldThrowErrorSync( () => _.identity.identityGet({ profileDir, selector : undefined }) );
}

//

function identitySet( test )
{
  const profileDir = `test-${ _.intRandom( 1000000 ) }`;

  /* */

  test.case = 'set no properties in identity in config that not exists, force - 1';
  var config = _.censor.configRead({ profileDir });
  test.identical( config, null );
  var got = _.identity.identitySet({ profileDir, selector : 'user', set : {}, force : 1 });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  test.identical( config, { about : {}, path : {} } );
  _.censor.profileDel( profileDir );

  test.case = 'set properties into identity in config that not exists, force - 1';
  var config = _.censor.configRead({ profileDir });
  test.identical( config, null );
  var got = _.identity.identitySet({ profileDir, selector : 'user', set : { login : 'userLogin' }, force : 1 });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  test.identical( config, { about : {}, path : {}, identity : { user : { login : 'userLogin' } } } );
  _.censor.profileDel( profileDir );

  /* */

  test.case = 'set no properties in identity in config that exists, identities not exist, force - 1';
  _.censor.configSet({ profileDir, set : { about : { name : profileDir } } });
  var config = _.censor.configRead({ profileDir });
  test.identical( config, { about : { name : profileDir }, path : {} } );
  var got = _.identity.identitySet({ profileDir, selector : 'user', set : {}, force : 1 });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  test.identical( config, { about : { name : profileDir }, path : {} } );
  _.censor.profileDel( profileDir );

  test.case = 'set properties in identity in config that exists, identities not exist, force - 1';
  _.censor.configSet({ profileDir, set : { about : { name : profileDir } } });
  var config = _.censor.configRead({ profileDir });
  test.identical( config, { about : { name : profileDir }, path : {} } );
  var got = _.identity.identitySet({ profileDir, selector : 'user', set : { login : 'userLogin' }, force : 1 });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  test.identical( config, { about : { name : profileDir }, path : {}, identity : { user : { login : 'userLogin' } } } );
  _.censor.profileDel( profileDir );

  /* */

  test.case = 'set no properties in identity in config that exists, single identity, selector matches identity';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.identical( config.identity, { user : { login : 'userLogin', type : 'git' } } );
  var got = _.identity.identitySet({ profileDir, selector : 'user', set : {} });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  test.identical( config.identity, { user : { login : 'userLogin', type : 'git' } } );
  _.censor.profileDel( profileDir );

  test.case = 'set properties in identity in config that exists, single identity, selector matches identity, replace';
  var identity = { name : 'user', login : 'userLogin', type : 'npm' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.identical( config.identity, { user : { login : 'userLogin', type : 'npm' } } );
  var got = _.identity.identitySet({ profileDir, selector : 'user', set : { type : 'git' } });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  test.identical( config.identity, { user : { login : 'userLogin', type : 'git' } } );
  _.censor.profileDel( profileDir );

  test.case = 'set properties in identity in config that exists, single identity, selector matches identity, extend';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.identical( config.identity, { user : { login : 'userLogin', type : 'git' } } );
  var got = _.identity.identitySet({ profileDir, selector : 'user', set : { email : 'user@domain.com' } });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  test.identical( config.identity, { user : { login : 'userLogin', type : 'git', email : 'user@domain.com' } } );
  _.censor.profileDel( profileDir );

  /* */

  test.case = 'set no properties in identity in config that exists, single identity, selector matches not identity, force - 1';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.identical( config.identity, { user : { login : 'userLogin', type : 'git' } } );
  var got = _.identity.identitySet({ profileDir, selector : 'user2', set : {}, force : 1 });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  test.identical( config.identity, { user : { login : 'userLogin', type : 'git' } } );
  _.censor.profileDel( profileDir );

  test.case = 'set properties in identity in config that exists, single identity, selector matches not identity, force - 1';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.identical( config.identity, { user : { login : 'userLogin', type : 'git' } } );
  var got = _.identity.identitySet({ profileDir, selector : 'user2', set : { login : 'userLogin2' }, force : 1 });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  test.identical( config.identity, { user : { login : 'userLogin', type : 'git' }, user2 : { login : 'userLogin2' } } );
  _.censor.profileDel( profileDir );

  /* */

  test.case = 'set no properties in identity in config that exists, several identities, selector with glob, matches identities';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var identity = { name : 'user2', login : 'userLogin2', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.true( _.map.is( config.identity ) );
  var got = _.identity.identitySet({ profileDir, selector : 'user*', set : {} });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  var exp =
  {
    user : { login : 'userLogin', type : 'git' },
    user2 : { login : 'userLogin2', type : 'git' }
  };
  test.identical( config.identity, exp );
  _.censor.profileDel( profileDir );

  test.case = 'set properties in identity in config that exists, several identities, selector with glob, matches identities';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var identity = { name : 'user2', login : 'userLogin2', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.true( _.map.is( config.identity ) );
  var got = _.identity.identitySet({ profileDir, selector : 'user*', set : { login : 'userLogin3' } });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  var exp =
  {
    'user' : { login : 'userLogin3', type : 'git' },
    'user2' : { login : 'userLogin3', type : 'git' },
  };
  test.identical( config.identity, exp );
  _.censor.profileDel( profileDir );

  /* - */

  if( !Config.debug )
  return;

  test.case = 'without arguments';
  test.shouldThrowErrorSync( () => _.identity.identitySet() );

  test.case = 'extra arguments';
  var o = { profileDir, selector : 'user', set : {} };
  test.shouldThrowErrorSync( () => _.identity.identitySet( o, o ) );

  test.case = 'wrong type of options map';
  test.shouldThrowErrorSync( () => _.identity.identitySet([ { profileDir, selector : 'user', set : {}, force : 1 } ]) );

  test.case = 'unknown option in options map';
  test.shouldThrowErrorSync( () => _.identity.identitySet({ profileDir, selector : 'user', set : {}, force : 1, unknown : 1 }) );

  test.case = 'o.selector is not defined string';
  test.shouldThrowErrorSync( () => _.identity.identitySet({ profileDir, selector : '', set : {}, force : 1 }) );

  test.case = 'wrong type of o.set';
  test.shouldThrowErrorSync( () => _.identity.identitySet({ profileDir, selector : 'user', set : null, force : 1 }) );

  test.case = 'identity does not exists, force - 0';
  test.shouldThrowErrorSync( () => _.identity.identitySet({ profileDir, selector : 'user', set : {}, force : 0 }) );
  _.censor.profileDel( profileDir );
}

//

function identitySetWithResolving( test )
{
  const profileDir = `test-${ _.intRandom( 1000000 ) }`;

  /* */

  test.case = 'resolve data from config';
  _.censor.configSet({ profileDir, set : { about : { name : 'user', email : 'user@domain.com' } } });
  var config = _.censor.configRead({ profileDir });
  test.identical( config, { about : { name : 'user', email : 'user@domain.com' }, path : {} } );
  var got = _.identity.identitySet
  ({
    profileDir,
    selector : 'from.about',
    set : { login : '{about/name}', email : '{about/email}' },
    force : 1
  });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  var exp =
  {
    about : { name : 'user', email : 'user@domain.com' },
    path : {},
    identity : { 'from.about' : { login : 'user', email : 'user@domain.com' } },
  };
  test.identical( config, exp );
  _.censor.profileDel( profileDir );
}

//

function identityNew( test )
{
  const profileDir = `test-${ _.intRandom( 1000000 ) }`;

  /* - */

  test.case = 'add identity to not existed config';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  var got = _.identity.identityNew({ profileDir, identity });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  test.identical( config.identity, { user : { login : 'userLogin', type : 'git' } } );
  _.censor.profileDel( profileDir );

  test.case = 'add identity to existed config';
  _.censor.configSet({ profileDir, set : { about : { name : profileDir } } });
  var config = _.censor.configRead({ profileDir });
  test.identical( config, { about : { name : profileDir }, path : {} } );
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  var got = _.identity.identityNew({ profileDir, identity });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  test.identical( config.about, { name : profileDir } );
  test.identical( config.path, {} );
  test.identical( config.identity, { user : { login : 'userLogin', type : 'git' } } );
  _.censor.profileDel( profileDir );

  test.case = 'add several identities to not existed config';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var identity = { name : 'user2', login : 'userLogin2', type : 'npm' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  var exp =
  {
    user : { login : 'userLogin', type : 'git' },
    user2 : { login : 'userLogin2', type : 'npm' }
  };
  test.identical( config.identity, exp );
  _.censor.profileDel( profileDir );

  test.case = 'add several identities to existed config';
  _.censor.configSet({ profileDir, set : { about : { name : profileDir } } });
  var config = _.censor.configRead({ profileDir });
  test.identical( config, { about : { name : profileDir }, path : {} } );
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var identity = { name : 'user2', login : 'userLogin2', type : 'npm' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  var exp =
  {
    user : { login : 'userLogin', type : 'git' },
    user2 : { login : 'userLogin2', type : 'npm' }
  };
  test.identical( config.about, { name : profileDir } );
  test.identical( config.path, {} );
  test.identical( config.identity, exp );
  _.censor.profileDel( profileDir );

  test.case = 'create identity with user defined fields';
  var identity = { name : 'user', login : 'userLogin', type : 'git', email : 'user@domain.com', token : 'someToken' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  var exp = { user : { login : 'userLogin', type : 'git', email : 'user@domain.com', token : 'someToken' } };
  test.identical( config.identity, exp );
  _.censor.profileDel( profileDir );

  /* - */

  test.case = 'create superidentity with string identities';
  var identity = { name : 'user', type : 'super', identities : 'foo' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  var exp = { user : { type : 'super', identities : { 'foo' : true } } };
  test.identical( config.identity, exp );
  _.censor.profileDel( profileDir );

  test.case = 'create superidentity with array of strings identities';
  var identity = { name : 'user', type : 'super', identities : [ 'foo', 'bar' ] };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  var exp = { user : { type : 'super', identities : { 'foo' : true, 'bar' : true } } };
  test.identical( config.identity, exp );
  _.censor.profileDel( profileDir );

  test.case = 'create superidentity with map of identities';
  var identity = { name : 'user', type : 'super', identities : { 'foo' : true, 'bar' : true } };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  var exp = { user : { type : 'super', identities : { 'foo' : true, 'bar' : true } } };
  test.identical( config.identity, exp );
  _.censor.profileDel( profileDir );

  /* - */

  test.case = 'rewrite identity with the existed name, force - 1';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  var exp = { user : { login : 'userLogin', type : 'git' } };
  test.identical( config.identity, exp );
  var identity = { name : 'user', login : 'userLogin2', email : 'user@domain.com', type : 'git' };
  _.identity.identityNew({ profileDir, identity, force : 1 });
  var config = _.censor.configRead({ profileDir });
  var exp = { user : { login : 'userLogin2', type : 'git', email : 'user@domain.com' } };
  test.identical( config.identity, exp );
  _.censor.profileDel( profileDir );

  /* - */

  if( !Config.debug )
  return;

  test.case = 'without arguments';
  test.shouldThrowErrorSync( () => _.identity.identityNew() );

  test.case = 'extra arguments';
  var o = { profileDir, identity : { name : 'user', login : 'userLogin' } };
  test.shouldThrowErrorSync( () => _.identity.identityNew( o, o ) );

  test.case = 'wrong type of options map';
  test.shouldThrowErrorSync( () => _.identity.identityNew( 'wrong' ) );

  test.case = 'unknown option in options map';
  var o = { profileDir, identity : { name : 'user', login : 'userLogin', type : 'git' }, unknown : 1 };
  test.shouldThrowErrorSync( () => _.identity.identityNew( o ) );

  test.case = 'wrong type of o.identity';
  var o = { profileDir, identity : [ { name : 'user', login : 'userLogin', type : 'git' } ] };
  test.shouldThrowErrorSync( () => _.identity.identityNew( o ) );

  test.case = 'unknown o.identity.type';
  var o = { profileDir, identity : { name : 'user', login : 'userLogin', type : 'unknown' } };
  test.shouldThrowErrorSync( () => _.identity.identityNew( o ) );

  test.case = 'o.identity.name is not defined string';
  var o = { profileDir, identity : { name : '', login : 'userLogin', type : 'git' } };
  test.shouldThrowErrorSync( () => _.identity.identityNew( o ) );
  var o = { profileDir, identity : { name : null, login : 'userLogin', type : 'git' } };
  test.shouldThrowErrorSync( () => _.identity.identityNew( o ) );

  test.case = 'o.identity.*login is not defined string';
  var o = { profileDir, identity : { name : 'user', login : '', type : 'git' } };
  test.shouldThrowErrorSync( () => _.identity.identityNew( o ) );
  var o = { profileDir, identity : { name : 'user', login : null, type : 'git' } };
  test.shouldThrowErrorSync( () => _.identity.identityNew( o ) );
  var o = { profileDir, identity : { 'name' : 'user', 'git.login' : '', 'type' : 'git' } };
  test.shouldThrowErrorSync( () => _.identity.identityNew( o ) );
  var o = { profileDir, identity : { 'name' : 'user', 'git.login' : null, 'type' : 'git' } };
  test.shouldThrowErrorSync( () => _.identity.identityNew( o ) );

  test.case = 'try to create identity with the existed name';
  var o = { profileDir, identity : { name : 'user', login : 'userLogin', type : 'git' } };
  _.identity.identityNew( o );
  var o = { profileDir, identity : { name : 'user', login : 'different', type : 'git' } };
  test.shouldThrowErrorSync( () => _.identity.identityNew( o ) );
  _.censor.profileDel( profileDir );

  test.case = 'superidentity has no field `identities`';
  var o = { profileDir, identity : { name : 'user', type : 'super' } };
  test.shouldThrowErrorSync( () => _.identity.identityNew( o ) );

  test.case = 'superidentity has wrong field `identities`';
  var o = { profileDir, identity : { name : 'user', type : 'super', identities : null } };
  test.shouldThrowErrorSync( () => _.identity.identityNew( o ) );
  _.censor.profileDel( profileDir );
}

//

function identityNewWithResolving( test )
{
  const profileDir = `test-${ _.intRandom( 1000000 ) }`;

  /* */

  test.case = 'resolve data from config';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.identical( config.identity, { user : { login : 'userLogin', type : 'git' } } );
  var got = _.identity.identityNew
  ({
    profileDir,
    identity : { name : 'from.identity', login : '{identity/user/login}', type : 'git' },
  });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  var exp =
  {
    'user' : { login : 'userLogin', type : 'git' },
    'from.identity' : { login : 'userLogin', type : 'git' },
  };
  test.identical( config.identity, exp );
  _.censor.profileDel( profileDir );
}

//

function identityFromWithGit( test )
{
  const a = test.assetFor( false );

  if( !_.process.insideTestContainer() )
  return test.true( true );

  a.fileProvider.dirMake( a.abs( '.' ) );
  const profileDir = `test-${ _.intRandom( 1000000 ) }`;
  const originalConfig = a.fileProvider.fileRead( a.fileProvider.configUserPath( '.gitconfig' ) );

  /* */

  a.ready.then( () =>
  {
    test.case = 'make new identity from git config, selector - undefined';
    var identity = { name : 'user', login : 'userLogin', email : 'user@domain.com', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var config = _.censor.configRead({ profileDir });
    var exp = { user : { login : 'userLogin', type : 'git', email : 'user@domain.com' } };
    test.identical( config.identity, exp );
    _.censor.profileHookCallWithIdentity({ profileDir, identity : config.identity.user });
    var got = _.identity.identityFrom({ profileDir, type : 'git' });
    test.identical( got, undefined );
    var config = _.censor.configRead({ profileDir });
    var exp =
    {
      user : { login : 'userLogin', type : 'git', email : 'user@domain.com' },
      userLogin : { 'git.login' : 'userLogin', 'git.email' : 'user@domain.com', 'type' : 'git' },
    };
    test.identical( config.identity, exp );
    _.censor.profileDel( profileDir );
    return null;
  });

  /* */

  a.ready.then( () =>
  {
    test.case = 'make new identity from git config, selector - string';
    var identity = { name : 'user', login : 'userLogin', email : 'user@domain.com', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var config = _.censor.configRead({ profileDir });
    var exp = { user : { login : 'userLogin', type : 'git', email : 'user@domain.com' } };
    test.identical( config.identity, exp );
    _.censor.profileHookCallWithIdentity({ profileDir, identity : config.identity.user });
    var got = _.identity.identityFrom({ profileDir, selector : 'git', type : 'git' });
    test.identical( got, undefined );
    var config = _.censor.configRead({ profileDir });
    var exp =
    {
      user : { login : 'userLogin', type : 'git', email : 'user@domain.com' },
      git : { 'git.login' : 'userLogin', 'git.email' : 'user@domain.com', 'type' : 'git' },
    };
    test.identical( config.identity, exp );
    _.censor.profileDel( profileDir );
    return null;
  });

  /* */

  a.ready.then( () =>
  {
    test.case = 'extend existed identity by specifique options';
    var identity = { name : 'user', login : 'userLogin', email : 'user@domain.com', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var identity = { name : 'user2', login : 'userLogin2', email : 'user2@domain.com', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var config = _.censor.configRead({ profileDir });
    var exp =
    {
      user : { login : 'userLogin', type : 'git', email : 'user@domain.com' },
      user2 : { login : 'userLogin2', type : 'git', email : 'user2@domain.com' },
    };
    test.identical( config.identity, exp );
    _.censor.profileHookCallWithIdentity({ profileDir, identity : config.identity.user2 });
    var got = _.identity.identityFrom({ profileDir, selector : 'user', type : 'git', force : 1 });
    test.identical( got, undefined );
    var config = _.censor.configRead({ profileDir });
    var exp =
    {
      user :
      {
        'login' : 'userLogin',
        'type' : 'git',
        'email' : 'user@domain.com',
        'git.login' : 'userLogin2',
        'git.email' : 'user2@domain.com'
      },
      user2 : { login : 'userLogin2', type : 'git', email : 'user2@domain.com' },
    };
    test.identical( config.identity, exp );
    _.censor.profileDel( profileDir );
    return null;
  });

  /* */

  a.ready.then( () =>
  {
    test.case = 'rewrite existed identity by specifique options';
    var identity = { 'name' : 'user', 'git.login' : 'userLogin', 'git.email' : 'user@domain.com', 'type' : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var identity = { name : 'user2', login : 'userLogin2', email : 'user2@domain.com', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var config = _.censor.configRead({ profileDir });
    var exp =
    {
      user : { 'type' : 'git', 'git.login' : 'userLogin', 'git.email' : 'user@domain.com' },
      user2 : { login : 'userLogin2', type : 'git', email : 'user2@domain.com' },
    };
    test.identical( config.identity, exp );
    _.censor.profileHookCallWithIdentity({ profileDir, identity : config.identity.user2 });
    var got = _.identity.identityFrom({ profileDir, selector : 'user', type : 'git', force : 1 });
    test.identical( got, undefined );
    var config = _.censor.configRead({ profileDir });
    var exp =
    {
      user : { 'type' : 'git', 'git.login' : 'userLogin2', 'git.email' : 'user2@domain.com' },
      user2 : { login : 'userLogin2', type : 'git', email : 'user2@domain.com' },
    };
    test.identical( config.identity, exp );
    _.censor.profileDel( profileDir );
    return null;
  });

  /* */

  if( Config.debug )
  {
    a.ready.then( () =>
    {
      if( !Config.debug )
      return;

      test.case = 'without arguments';
      test.shouldThrowErrorSync( () => _.identity.identityFrom() );

      test.case = 'extra arguments';
      var o = { profileDir, selector : 'user', type : 'git' };
      test.shouldThrowErrorSync( () => _.identity.identityFrom( o, o ) );

      test.case = 'wrong type of options map';
      test.shouldThrowErrorSync( () => _.identity.identityFrom( 'wrong' ) );

      test.case = 'unknown option in options map';
      test.shouldThrowErrorSync( () => _.identity.identityFrom({ profileDir, selector : 'user', type : 'git', unknown : 1 }) );

      test.case = 'o.selector is not defined string';
      test.shouldThrowErrorSync( () => _.identity.identityFrom({ profileDir, selector : undefined, type : 'git' }) );
      test.shouldThrowErrorSync( () => _.identity.identityFrom({ profileDir, selector : '', type : 'git' }) );

      test.case = 'o.selector is string with glob';
      test.shouldThrowErrorSync( () => _.identity.identityFrom({ profileDir, selector : 'user*', type : 'git' }) );

      test.case = 'wrong type of o.type';
      test.shouldThrowErrorSync( () => _.identity.identityFrom({ profileDir, selector : 'user', type : null }) );

      test.case = 'identity exists, force - 0';
      var identity = { name : 'user', login : 'userLogin', type : 'git' };
      _.identity.identityNew({ profileDir, identity });
      test.shouldThrowErrorSync( () => _.identity.identityFrom({ profileDir, selector : 'user', type : 'git', force : false }) );
      _.censor.profileDel( profileDir );
      return null;
    });
  }

  /* - */

  a.ready.finally( ( err, arg ) =>
  {
    a.fileProvider.fileWrite( a.fileProvider.configUserPath( '.gitconfig' ), originalConfig );
    if( err )
    throw _.err( err );
    return arg;
  });

  /* - */

  return a.ready;
}

//

function identityFromWithSsh( test )
{
  const a = test.assetFor( false );

  if( !_.process.insideTestContainer() )
  return test.true( true );

  a.fileProvider.dirMake( a.abs( '.' ) );
  const profileDir = `test-${ _.intRandom( 1000000 ) }`;
  let originalExists = false;
  const originalPath = a.fileProvider.configUserPath( '.ssh' );
  const backupPath = a.fileProvider.configUserPath( '.ssh.bak' );
  if( _.fileProvider.fileExists( originalPath ) )
  originalExists = true;

  begin();

  /* - */

  writeKey( 'id_rsa' ).then( () =>
  {
    test.case = 'make new identity from ssh, selector - undefined';
    var identity = { name : 'user', login : 'userLogin', email : 'user@domain.com', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var config = _.censor.configRead({ profileDir });
    var exp = { user : { login : 'userLogin', type : 'git', email : 'user@domain.com' } };
    test.identical( config.identity, exp );
    var got = _.identity.identityFrom({ profileDir, type : 'ssh' });
    test.identical( got, undefined );
    var config = _.censor.configRead({ profileDir });
    var exp =
    {
      user : { login : 'userLogin', type : 'git', email : 'user@domain.com' },
      id_rsa : { 'ssh.login' : 'id_rsa', 'ssh.path' : a.path.join( '.censor', profileDir, 'ssh', 'id_rsa' ), 'type' : 'ssh' },
    };
    test.identical( config.identity, exp );
    _.censor.profileDel( profileDir );
    return null;
  });

  /* */

  a.ready.then( () =>
  {
    test.case = 'make new ssh identity from default key, selector - string';
    var identity = { name : 'user', login : 'userLogin', email : 'user@domain.com', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var config = _.censor.configRead({ profileDir });
    var exp = { user : { login : 'userLogin', type : 'git', email : 'user@domain.com' } };
    test.identical( config.identity, exp );
    var got = _.identity.identityFrom({ profileDir, selector : 'ssh', type : 'ssh' });
    test.identical( got, undefined );
    var config = _.censor.configRead({ profileDir });
    var exp =
    {
      user : { login : 'userLogin', type : 'git', email : 'user@domain.com' },
      ssh : { 'ssh.login' : 'ssh', 'ssh.path' : a.path.join( '.censor', profileDir, 'ssh', 'ssh' ), 'type' : 'ssh' },
    };
    test.identical( config.identity, exp );
    _.censor.profileDel( profileDir );
    return null;
  });

  /* */

  a.ready.then( () =>
  {
    test.case = 'extend existed identity by specifique options';
    var identity = { name : 'user', login : 'userLogin', email : 'user@domain.com', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var config = _.censor.configRead({ profileDir });
    var exp =
    {
      user : { login : 'userLogin', type : 'git', email : 'user@domain.com' },
    };
    test.identical( config.identity, exp );
    var got = _.identity.identityFrom({ profileDir, selector : 'user', type : 'ssh', force : 1 });
    test.identical( got, undefined );
    var config = _.censor.configRead({ profileDir });
    var exp =
    {
      user :
      {
        'login' : 'userLogin',
        'type' : 'ssh',
        'email' : 'user@domain.com',
        'ssh.login' : 'user',
        'ssh.path' : a.path.join( '.censor', profileDir, 'ssh', 'user' ),
      },
    };
    test.identical( config.identity, exp );
    _.censor.profileDel( profileDir );
    return null;
  });

  /* */

  writeKey( 'user2' ).then( () =>
  {
    test.case = 'make new ssh identity from key with identity name, selector - string';
    var identity = { name : 'user', login : 'userLogin', email : 'user@domain.com', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var config = _.censor.configRead({ profileDir });
    var exp = { user : { login : 'userLogin', type : 'git', email : 'user@domain.com' } };
    test.identical( config.identity, exp );
    var got = _.identity.identityFrom({ profileDir, selector : 'user2', type : 'ssh' });
    test.identical( got, undefined );
    var config = _.censor.configRead({ profileDir });
    var exp =
    {
      user : { login : 'userLogin', type : 'git', email : 'user@domain.com' },
      user2 : { 'ssh.login' : 'user2', 'ssh.path' : a.path.join( '.censor', profileDir, 'ssh', 'user2' ), 'type' : 'ssh' },
    };
    test.identical( config.identity, exp );
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

function identityDel( test )
{
  const profileDir = `test-${ _.intRandom( 1000000 ) }`;

  /* */

  delAllIdentities( profileDir );
  delAllIdentities({ profileDir });
  delAllIdentities({ profileDir, selector : null });
  delAllIdentities({ profileDir, selector : '' });

  /* */

  function delAllIdentities( arg )
  {
    test.open( `${ _.entity.exportStringSolo( arg ) }` );

    test.case = 'del identities from not existed config';
    var config = _.censor.configRead({ profileDir });
    test.identical( config, null );
    var got = _.identity.identityDel( _.entity.make( arg ) );
    test.identical( got, undefined );
    var config = _.censor.configRead({ profileDir });
    test.identical( config, { about : {}, path : {} } );
    _.censor.profileDel( profileDir );

    test.case = 'del identities from existed config, identities not exist';
    _.censor.configSet({ profileDir, set : { about : { name : profileDir } } });
    var config = _.censor.configRead({ profileDir });
    test.identical( config, { about : { name : profileDir }, path : {} } );
    var got = _.identity.identityDel( _.entity.make( arg ) );
    test.identical( got, undefined );
    var config = _.censor.configRead({ profileDir });
    test.identical( config, { about : { name : profileDir }, path : {} } );
    _.censor.profileDel( profileDir );

    test.case = 'del identities from existed config, single identity';
    var identity = { name : 'user', login : 'userLogin', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var config = _.censor.configRead({ profileDir });
    test.true( _.map.is( config.identity ) );
    var got = _.identity.identityDel( _.entity.make( arg ) );
    test.identical( got, undefined );
    var config = _.censor.configRead({ profileDir });
    test.identical( config, { about : {}, path : {} } );
    _.censor.profileDel( profileDir );

    test.case = 'del identities from existed config, several identities';
    var identity = { name : 'user', login : 'userLogin', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var identity = { name : 'user2', login : 'userLogin2', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var config = _.censor.configRead({ profileDir });
    test.true( _.map.is( config.identity ) );
    var got = _.identity.identityDel( _.entity.make( arg ) );
    test.identical( got, undefined );
    var config = _.censor.configRead({ profileDir });
    test.identical( config, { about : {}, path : {} } );
    _.censor.profileDel( profileDir );

    test.close( `${ _.entity.exportStringSolo( arg ) }` );
  }

  /* - */

  test.open( 'with selector' );

  test.case = 'del identity from not existed config';
  var config = _.censor.configRead({ profileDir });
  test.identical( config, null );
  var got = _.identity.identityDel({ profileDir, selector : 'user' });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  test.identical( config, { about : {}, path : {} } );
  _.censor.profileDel( profileDir );

  test.case = 'del identity from existed config, identities not exist';
  _.censor.configSet({ profileDir, set : { about : { name : profileDir } } });
  var config = _.censor.configRead({ profileDir });
  test.identical( config, { about : { name : profileDir }, path : {} } );
  var got = _.identity.identityDel({ profileDir, selector : 'user' });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  test.identical( config, { about : { name : profileDir }, path : {} } );
  _.censor.profileDel( profileDir );

  test.case = 'del identity from existed config, single identity, selector matches identity';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.true( _.map.is( config.identity ) );
  var got = _.identity.identityDel({ profileDir, selector : 'user' });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  test.identical( config, { about : {}, path : {}, identity : {} } );
  _.censor.profileDel( profileDir );

  test.case = 'del identity from existed config, single identity, selector matches not identity';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.true( _.map.is( config.identity ) );
  var got = _.identity.identityDel({ profileDir, selector : 'user2' });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  test.identical( config.identity, { user : { login : 'userLogin', type : 'git' } } );
  _.censor.profileDel( profileDir );

  test.case = 'del identity from existed config, several identities, selector matches identity';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var identity = { name : 'user2', login : 'userLogin2', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.true( _.map.is( config.identity ) );
  var got = _.identity.identityDel({ profileDir, selector : 'user2' });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  test.identical( config.identity, { user : { login : 'userLogin', type : 'git' } } );
  _.censor.profileDel( profileDir );

  test.case = 'del identity from existed config, several identities, selector matches not identity';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var identity = { name : 'user2', login : 'userLogin2', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.true( _.map.is( config.identity ) );
  var got = _.identity.identityDel({ profileDir, selector : 'user3' });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  var exp =
  {
    user : { login : 'userLogin', type : 'git' },
    user2 : { login : 'userLogin2', type : 'git' },
  };
  test.identical( config.identity, exp );
  _.censor.profileDel( profileDir );

  test.case = 'del identity from existed config, several identities, selector with glob';
  var identity = { name : 'user', login : 'userLogin', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var identity = { name : 'user2', login : 'userLogin2', type : 'git' };
  _.identity.identityNew({ profileDir, identity });
  var config = _.censor.configRead({ profileDir });
  test.true( _.map.is( config.identity ) );
  var got = _.identity.identityDel({ profileDir, selector : 'user*' });
  test.identical( got, undefined );
  var config = _.censor.configRead({ profileDir });
  var exp =
  {
    user : { login : 'userLogin', type : 'git' },
    user2 : { login : 'userLogin2', type : 'git' },
  };
  test.identical( config.identity, exp );
  _.censor.profileDel( profileDir );

  test.close( 'with selector' );

  /* - */

  if( !Config.debug )
  return;

  test.case = 'without arguments';
  test.shouldThrowErrorSync( () => _.identity.identityDel() );

  test.case = 'extra arguments';
  test.shouldThrowErrorSync( () => _.identity.identityDel( profileDir, profileDir ) );

  test.case = 'wrong type of options map';
  test.shouldThrowErrorSync( () => _.identity.identityDel([ profileDir ]) );

  test.case = 'unknown option in options map';
  test.shouldThrowErrorSync( () => _.identity.identityDel({ profileDir, selector : '', unknown : 1 }) );

  test.case = 'wrong type of o.selector';
  test.shouldThrowErrorSync( () => _.identity.identityDel({ profileDir, selector : undefined }) );
}

//

function identityDelWithSshKeys( test )
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
    var got = _.identity.identityDel({ profileDir, selector : 'user' });
    test.identical( got, undefined );
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml', './ssh' ] );
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

function identityUse( test )
{
  const a = test.assetFor( false );

  if( !_.process.insideTestContainer() )
  return test.true( true );

  a.fileProvider.dirMake( a.abs( '.' ) );
  const profileDir = `test-${ _.intRandom( 1000000 ) }`;
  const userProfileDir = a.fileProvider.configUserPath( `.censor/${ profileDir }` );

  const originalConfig = a.fileProvider.fileRead( a.fileProvider.configUserPath( '.gitconfig' ) );

  const hook =
`function onIdentity( identity )
{
  const _ = this;
  _.identity.identitySet({ profileDir : '${ profileDir }', selector : 'user', set : { email : 'user@domain.com' } });
}
module.exports = onIdentity;`;

  /* - */

  begin().then( () =>
  {
    test.case = 'use git identity from scratch, no type';
    var identity = { name : 'user', login : 'userLogin', email : 'user@domain.com', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml' ] );
    var config = _.censor.configRead({ profileDir });
    test.identical( config.identity.user, { login : 'userLogin', email : 'user@domain.com', type : 'git' } );
    test.identical( config.identity[ '_previous.git' ], undefined );
    var got = _.identity.identityUse({ profileDir, type : 'git', selector : 'user' });
    test.identical( got, undefined );
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml' ] );
    var config = _.censor.configRead({ profileDir });
    test.identical( config.identity.user, { login : 'userLogin', type : 'git', email : 'user@domain.com' } );
    test.identical( config.identity[ '_previous.git' ], undefined );
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
    test.case = 'use git identity from scratch';
    var identity = { name : 'user', login : 'userLogin', email : 'user@domain.com', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml' ] );
    var config = _.censor.configRead({ profileDir });
    test.identical( config.identity.user, { login : 'userLogin', type : 'git', email : 'user@domain.com' } );
    test.identical( config.identity[ '_previous.git' ], undefined );
    var got = _.identity.identityUse({ profileDir, type : 'git', selector : 'user' });
    test.identical( got, undefined );
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml' ] );
    var config = _.censor.configRead({ profileDir });
    test.identical( config.identity.user, { login : 'userLogin', type : 'git', email : 'user@domain.com' } );
    test.identical( config.identity[ '_previous.git' ], undefined );
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
    test.case = 'switch several identities with superidentity';
    var identity = { name : 'user', login : 'userLogin', email : 'user@domain.com', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var identity = { name : 'user2', login : 'userLogin2', email : 'user2@domain.com', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    var identity = { name : 'user3', type : 'super', identities : { user : false, user2 : true } };
    _.identity.identityNew({ profileDir, identity });
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml' ] );
    var config = _.censor.configRead({ profileDir });
    test.identical( config.identity.user, { login : 'userLogin', type : 'git', email : 'user@domain.com' } );
    test.identical( config.identity.user2, { login : 'userLogin2', email : 'user2@domain.com', type : 'git' } );
    test.identical( config.identity.user3, { type : 'super', identities : { user : false, user2 : true } } );
    test.identical( config.identity[ '_previous.git' ], undefined );

    var got = _.identity.identityUse({ profileDir, type : 'git', selector : 'user' });
    test.identical( got, undefined );
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml' ] );
    var config = _.censor.configRead({ profileDir });
    test.identical( config.identity.user, { login : 'userLogin', type : 'git', email : 'user@domain.com' } );
    test.identical( config.identity.user2, { login : 'userLogin2', email : 'user2@domain.com', type : 'git' } );
    test.identical( config.identity.user3, { type : 'super', identities : { user : false, user2 : true } } );
    test.identical( config.identity[ '_previous.git' ], undefined );

    var got = _.identity.identityUse({ profileDir, type : 'git', selector : 'user3' });
    test.identical( got, undefined );
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml' ] );
    var config = _.censor.configRead({ profileDir });
    test.identical( config.identity.user, { login : 'userLogin', type : 'git', email : 'user@domain.com' } );
    test.identical( config.identity.user2, { login : 'userLogin2', email : 'user2@domain.com', type : 'git' } );
    test.identical( config.identity.user3, { type : 'super', identities : { user : false, user2 : true } } );
    var exp = { 'git.login' : 'userLogin', 'type' : 'git', 'git.email' : 'user@domain.com' };
    test.identical( config.identity[ '_previous.git' ], exp );
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

  begin().then( () =>
  {
    test.case = 'call user hook';
    var identity = { name : 'user', type : 'git', login : 'userLogin' };
    _.identity.identityNew({ profileDir, identity });
    _.censor.profileHookSet({ profileDir, hook, type : 'git' });
    var config = _.censor.configRead({ profileDir });
    test.identical( config.identity.user.email, undefined );
    var got = _.identity.identityUse({ profileDir, type : 'git', selector : 'user' });
    test.identical( got, undefined );
    var config = _.censor.configRead({ profileDir });
    test.identical( config.identity.user.email, 'user@domain.com' );
    _.censor.profileDel( profileDir );
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

function identityUseSsh( test )
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
    test.case = 'change identity';
    _.identity.identityFrom({ profileDir, selector : 'user', type : 'ssh' });
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml', './ssh', './ssh/user', './ssh/user/id_rsa' ] );
    a.fileProvider.fileAppend( a.fileProvider.configUserPath( `.censor/${ profileDir }/ssh/user/id_rsa` ), '\nunique data' );
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
    var got = _.identity.identityUse({ profileDir, type : 'ssh', selector : 'user' });
    test.identical( got, undefined );
    var files = a.find( userProfileDir );
    var exp =
    [
      '.',
      './config.yaml',
      './ssh',
      './ssh/_previous.ssh',
      './ssh/_previous.ssh/id_rsa',
      './ssh/_previous.ssh/some_file',
      './ssh/user',
      './ssh/user/id_rsa',
      './ssh/user2',
      './ssh/user2/id_rsa',
      './ssh/user2/some_file',
    ];
    test.identical( files, exp );
    var data = a.fileProvider.fileRead( a.abs( originalPath, 'id_rsa' ) );
    test.identical( data, 'id_rsa\nunique data' );
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

function identityUpdate( test )
{
  if( !_.process.insideTestContainer() )
  return test.true( true );

  const a = test.assetFor( false );
  a.fileProvider.dirMake( a.abs( '.' ) );
  const profileDir = `test-${ _.intRandom( 1000000 ) }`;
  const originalConfig = a.fileProvider.fileRead( a.fileProvider.configUserPath( '.gitconfig' ) );

  begin().then( () =>
  {
    const identity = { name : 'user', login : 'userLogin', email : 'user@domain.com', type : 'git' };
    _.identity.identityNew({ profileDir, identity });
    _.identity.identityUse({ profileDir, selector : 'user', type : 'git' });
    return null;
  });

  /* - */

  a.ready.then( () =>
  {
    test.case = 'update not existed identity';
    var got = _.identity.identityGet({ profileDir, selector : 'user2' });
    test.identical( got, undefined );
    _.identity.identityUpdate({ profileDir, dst : 'user2', type : 'git' });
    var got = _.identity.identityGet({ profileDir, selector : 'user2' });
    test.identical( got, { 'type' : 'git', 'git.login' : 'userLogin', 'git.email' : 'user@domain.com' } );
    _.censor.profileDel( profileDir );
    return null;
  });

  a.ready.then( () =>
  {
    test.case = 'update existed identity, force - 1';
    const identity = { name : 'user2', login : 'userLogin2', email : 'user2@domain.com', type : 'npm' };
    _.identity.identityNew({ profileDir, identity });
    var got = _.identity.identityGet({ profileDir, selector : 'user2' });
    test.identical( got, { 'login' : 'userLogin2', 'email' : 'user2@domain.com', 'type' : 'npm' } );
    _.identity.identityUpdate({ profileDir, dst : 'user2', type : 'git', force : 1 });
    var got = _.identity.identityGet({ profileDir, selector : 'user2' });
    var exp =
    {
      'login' : 'userLogin2',
      'email' : 'user2@domain.com',
      'type' : 'git',
      'git.login' : 'userLogin',
      'git.email' : 'user@domain.com'
    };
    test.identical( got, exp );
    _.censor.profileDel( profileDir );
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

function identityResolveDefaultMaybe( test )
{
  const profileDir = `test-${ _.intRandom( 1000000 ) }`;
  const identities = { user21 : true, user22 : false, user3 : true };
  const superIdentity = { name : 'user', login : 'userLogin', type : 'super', identities, default : true };
  const serviceIdentity1 = { name : 'user21', login : 'userLogin', type : 'git', services : [ 'github.com', 'gitlab.com' ] };
  const serviceIdentity2 = { name : 'user22', login : 'userLogin', type : 'npm', services : [ 'npmjs.org' ] };
  const typeIdentity = { name : 'user3', login : 'userLogin', type : 'cargo', default : 1 };

  /* */

  test.case = 'resolve identity, no config';
  _.censor.profileDel( profileDir );
  var got = _.identity.identityResolveDefaultMaybe( profileDir );
  test.identical( got, null );
  _.censor.profileDel( profileDir );

  test.case = 'resolve no identity';
  _.identity.identityNew({ profileDir, identity : _.map.extend( null, serviceIdentity1 ) });
  _.identity.identityNew({ profileDir, identity : _.map.extend( null, serviceIdentity2 ) });
  var got = _.identity.identityResolveDefaultMaybe( profileDir );
  test.identical( got, undefined );
  _.censor.profileDel( profileDir );

  /* */

  test.case = 'several identities, single with default, search exactly default identity by string';
  _.identity.identityNew({ profileDir, identity : _.map.extend( null, superIdentity ) });
  _.identity.identityNew({ profileDir, identity : _.map.extend( null, serviceIdentity1 ) });
  _.identity.identityNew({ profileDir, identity : _.map.extend( null, serviceIdentity2 ) });
  var got = _.identity.identityResolveDefaultMaybe( profileDir );
  test.identical( got, _.mapBut_( null, superIdentity, [ 'name' ] ) );
  _.censor.profileDel( profileDir );

  test.case = 'several identities, single with default, search exactly default identity by map';
  _.identity.identityNew({ profileDir, identity : _.map.extend( null, superIdentity ) });
  _.identity.identityNew({ profileDir, identity : _.map.extend( null, serviceIdentity1 ) });
  _.identity.identityNew({ profileDir, identity : _.map.extend( null, serviceIdentity2 ) });
  var got = _.identity.identityResolveDefaultMaybe( { profileDir } );
  test.identical( got, _.mapBut_( null, superIdentity, [ 'name' ] ) );
  _.censor.profileDel( profileDir );

  /* */

  test.case = 'several identities without default identity, search by service';
  _.identity.identityNew({ profileDir, identity : _.map.extend( null, serviceIdentity1 ) });
  _.identity.identityNew({ profileDir, identity : _.map.extend( null, serviceIdentity2 ) });
  var got = _.identity.identityResolveDefaultMaybe( { profileDir, service : 'github.com' } );
  test.identical( got, _.mapBut_( null, serviceIdentity1, [ 'name' ] ) );
  var got = _.identity.identityResolveDefaultMaybe( { profileDir, service : 'gitlab.com' } );
  test.identical( got, _.mapBut_( null, serviceIdentity1, [ 'name' ] ) );
  var got = _.identity.identityResolveDefaultMaybe( { profileDir, service : 'npmjs.org' } );
  test.identical( got, _.mapBut_( null, serviceIdentity2, [ 'name' ] ) );
  _.censor.profileDel( profileDir );

  test.case = 'several identities, with default identity, search by type';
  _.identity.identityNew({ profileDir, identity : _.map.extend( null, serviceIdentity1 ) });
  _.identity.identityNew({ profileDir, identity : _.map.extend( null, serviceIdentity2, { default : true } ) });
  _.identity.identityNew({ profileDir, identity : _.map.extend( null, typeIdentity ) });
  var got = _.identity.identityResolveDefaultMaybe( { profileDir, type : 'npm' } );
  test.identical( _.mapBut_( null, got, [ 'default' ] ), _.mapBut_( null, serviceIdentity2, [ 'name' ] ) );
  _.censor.profileDel( profileDir );

  test.case = 'several identities, with default identity, duplicated, search by type';
  _.identity.identityNew({ profileDir, identity : _.map.extend( null, superIdentity ) });
  _.identity.identityNew({ profileDir, identity : _.map.extend( null, serviceIdentity1 ) });
  _.identity.identityNew({ profileDir, identity : _.map.extend( null, serviceIdentity2, { default : true } ) });
  _.identity.identityNew({ profileDir, identity : _.map.extend( null, typeIdentity ) });
  var got = _.identity.identityResolveDefaultMaybe( { profileDir, type : 'npm' } );
  test.identical( _.mapBut_( null, got, [ 'default' ] ), _.mapBut_( null, serviceIdentity2, [ 'name' ] ) );
  _.censor.profileDel( profileDir );

  /* - */

  if( !Config.debug )
  return;

  test.case = 'extra arguments';
  test.shouldThrowErrorSync( () => _.identity.identityResolveDefaultMaybe( profileDir, profileDir ) );

  test.case = 'wrong type of options map';
  test.shouldThrowErrorSync( () => _.identity.identityResolveDefaultMaybe([ profileDir ]) );

  test.case = 'unknown option in options map';
  test.shouldThrowErrorSync( () => _.identity.identityResolveDefaultMaybe({ profileDir, selector : '', unknown : 1 }) );

  test.case = 'wrong value of o.type';
  test.shouldThrowErrorSync( () => _.identity.identityResolveDefaultMaybe({ profileDir, type : 'wrong' }) );
}

//

function identitiesEquivalentAre( test )
{
  const a = test.assetFor( false );
  const profileDir = `test-${ _.intRandom( 1000000 ) }`;

  /* */

  test.case = 'compare equivalent identities';
  var identity1 = { name : 'user', login : 'userLogin', type : 'super' };
  var identity2 = { name : 'user', login : 'userLogin', type : 'git' };
  var got = _.identity.identitiesEquivalentAre({ profileDir, identity1, identity2, type : 'git' });
  test.identical( got, true );
  _.censor.profileDel( profileDir );

  test.case = 'compare not equivalent identities';
  var identity1 = { name : 'user', login : 'userLogin', type : 'super' };
  var identity2 = { name : 'user2', login : 'userLogin', type : 'git' };
  var got = _.identity.identitiesEquivalentAre({ profileDir, identity1, identity2, type : 'git' });
  test.identical( got, false );
  _.censor.profileDel( profileDir );
}

//

function identitiesEquivalentAreWithSsh( test )
{
  if( !_.process.insideTestContainer() )
  return test.true( true );

  const a = test.assetFor( false );
  const profileDir = `test-${ _.intRandom( 1000000 ) }`;
  a.fileProvider.dirMake( a.abs( '.' ) );
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
    test.case = 'compare equivalent ssh identities';
    _.identity.identityFrom({ profileDir, selector : 'user', type : 'ssh' });
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml', './ssh', './ssh/user', './ssh/user/id_rsa' ] );
    return null;
  });

  writeKey( 'id_rsa' ).then( () =>
  {
    test.case = 'change identity';
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
      './ssh/user2/id_rsa',
    ];
    test.identical( files, exp );
    return null;
  });
  a.ready.then( () =>
  {
    var identity1 = _.identity.identityGet({ profileDir, selector : 'user' });
    var identity2 = _.identity.identityGet({ profileDir, selector : 'user2' });
    var got = _.identity.identitiesEquivalentAre({ profileDir, identity1, identity2, type : 'ssh' });
    test.identical( got, true );

    _.censor.profileDel( profileDir );
    return null;
  });

  /* */

  writeKey( 'id_rsa' ).then( () =>
  {
    test.case = 'compare not equivalent ssh identities';
    _.identity.identityFrom({ profileDir, selector : 'user', type : 'ssh' });
    var files = a.find( userProfileDir );
    test.identical( files, [ '.', './config.yaml', './ssh', './ssh/user', './ssh/user/id_rsa' ] );
    a.fileProvider.fileAppend( a.fileProvider.configUserPath( `.censor/${ profileDir }/ssh/user/id_rsa` ), '\nunique data' );
    return null;
  });

  writeKey( 'id_rsa' ).then( () =>
  {
    test.case = 'change identity';
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
      './ssh/user2/id_rsa',
    ];
    test.identical( files, exp );
    return null;
  });
  a.ready.then( () =>
  {
    var identity1 = _.identity.identityGet({ profileDir, selector : 'user' });
    var identity2 = _.identity.identityGet({ profileDir, selector : 'user2' });
    var got = _.identity.identitiesEquivalentAre({ profileDir, identity1, identity2, type : 'ssh' });
    test.identical( got, false );

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

// --
// declare
// --

const Proto =
{
  name : 'Tools.mid.Identity',
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
    identityCopy,
    identityGet,
    identitySet,
    identitySetWithResolving,
    identityNew,
    identityNewWithResolving,
    identityFromWithGit,
    identityFromWithSsh,
    identityDel,
    identityDelWithSshKeys,
    identityUse,
    identityUseSsh,
    identityResolveDefaultMaybe,
    identityUpdate,
    identitiesEquivalentAre,
    identitiesEquivalentAreWithSsh,
  }
};

const Self = wTestSuite( Proto );
if( typeof module !== 'undefined' && !module.parent )
wTester.test( Self.name );

})();
