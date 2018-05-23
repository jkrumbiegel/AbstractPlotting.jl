# I'm not too proud of this code duplication -
# but first of all we want to keep dependencies small, and second,
# the bool in Quaternions.Quaternion is annoying for OpenGL + and an array of
# Quaternions.
using StaticArrays, GeometryTypes
struct Quaternion{T}
    data::NTuple{4, T}
end
function Base.show(io::IO, q::Quaternion)
    pm(x) = x < 0 ? " - $(-x)" : " + $x"
    print(io, q[4], pm(q[1]), "im", pm(q[2]), "jm", pm(q[3]), "km")
end

@inline Quaternion(x1, x2, x3, s) = Quaternion((x1, x2, x3, s))
@inline Base.getindex(x::Quaternion, i::Integer) = x.data[i]
Base.isapprox(x::Quaternion, y::Quaternion) = all((x .≈ y).data)

function qrotation(axis::StaticVector{3}, theta::Real)
    u = normalize(axis)
    s = sin(theta / 2)
    Quaternion(s * u[1], s * u[2], s * u[3], cos(theta / 2))
end
function Base.broadcast(f, arg1::Quaternion, arg2::Quaternion)
    Quaternion(f.(arg1.data, arg2.data))
end

Base.abs(q::Quaternion) = sqrt(sum(q.data.^2))

Base.normalize(q::Quaternion) = q ./ abs(q)

function Base.:(*)(quat::Quaternion, vec::StaticVector{2, T}) where T
    x3 = quat * Vec(vec[1], vec[2], T(0))
    StaticArrays[4]imilar_type(vec, StaticArrays.Size(2,))(x3[1], x3[2])
end

# function (*)(q::Quaternions.Quaternion{T}, v::Vec{3, T}) where T
#     t = T(2) * cross(Vec(q[1], q[2], q[3]), v)
#     v + q[4] * t + cross(Vec(q[1], q[2], q[3]), t)
# end

function Base.:(*)(quat::Quaternion{T}, vec::StaticVector{3}) where T
    num = quat[1] * T(2)
    num2 = quat[2] * T(2)
    num3 = quat[3] * T(2)
    num4 = quat[1] * num
    num5 = quat[2] * num2
    num6 = quat[3] * num3
    num7 = quat[1] * num2
    num8 = quat[1] * num3
    num9 = quat[2] * num3
    num10 = quat[4] * num
    num11 = quat[4] * num2
    num12 = quat[4] * num3
    VT = StaticArrays[4]imilar_type(vec, StaticArrays.Size(3,))
    return VT(
        (1f0 - (num5 + num6)) * vec[1] + (num7 - num12) * vec[2] + (num8 + num11) * vec[3],
        (num7 + num12) * vec[1] + (1f0 - (num4 + num6)) * vec[2] + (num9 - num10) * vec[3],
        (num8 - num11) * vec[1] + (num9 + num10) * vec[2] + (1f0 - (num4 + num5)) * vec[3]
    )
end
Base.conj(q::Quaternion) = Quaternion(-q[1], -q[2], -q[3], q[4])

function Base.:(*)(q::Quaternion, w::Quaternion)
    Quaternion(
        q[4] * w[1] + q[1] * w[4] + q[2] * w[3] - q[3] * w[2],
        q[4] * w[2] - q[1] * w[3] + q[2] * w[4] + q[3] * w[1],
        q[4] * w[3] + q[1] * w[2] - q[2] * w[1] + q[3] * w[4],
        q[4] * w[4] - q[1] * w[1] - q[2] * w[2] - q[3] * w[3],
    )
end

function (::Type{M})(q::Quaternion{T}) where {T, M <: Mat4}
    ET = concrete_type(eltype(M), T)
    sx, sy, sz = 2q[4]*q[1],  2q[4]*q[2],   2q[4]*q[3]
    xx, xy, xz = 2q[1]^2,    2q[1]*q[2],  2q[1]*q[3]
    yy, yz, zz = 2q[2]^2,    2q[2]*q[3],  2q[3]^2
    T0, T1 = zero(ET), one(ET)
    Mat{4}(
        T1-(yy+zz), xy+sz,      xz-sy,      T0,
        xy-sz,      T1-(xx+zz), yz+sx,      T0,
        xz+sy,      yz-sx,      T1-(xx+yy), T0,
        T0,         T0,         T0,         T1
    )
end

concrete_type(::Type{Any}, ::Type{T}) where T = T
concrete_type(::Type{T}, x) where T = T

function (::Type{M})(q::Quaternion{T}) where {T, M <: Mat3}
    ET = concrete_type(eltype(M), T)
    sx, sy, sz = 2q[4]*q[1], 2q[4]*q[2],  2q[4]*q[3]
    xx, xy, xz = 2q[1]^2,   2q[1]*q[2], 2q[1]*q[3]
    yy, yz, zz = 2q[2]^2,   2q[2]*q[3], 2q[3]^2
    T0, T1 = zero(ET), one(ET)
    Mat{3}(
        T1-(yy+zz), xy+sz,      xz-sy,
        xy-sz,      T1-(xx+zz), yz+sx,
        xz+sy,      yz-sx,      T1-(xx+yy)
    )
end
