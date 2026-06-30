namespace Softwyx.SptModTemplate.Interop;

/// <summary>Reflection access to obfuscated game members via <see cref="GameAssemblyNames" />.</summary>
internal static class GameMemberAccess{
    public static TField GetField<TField>(object instance, string fieldName){
        if(instance == null) return default;

        var field = AccessTools.Field(instance.GetType(), fieldName);

        if(field == null) return default;

        return (TField) field.GetValue(instance);
    }

    public static TProperty GetProperty<TProperty>(object instance, string propertyName){
        if(instance == null) return default;

        var property = AccessTools.Property(instance.GetType(), propertyName);

        if(property == null) return default;

        return (TProperty) property.GetValue(instance);
    }
}
